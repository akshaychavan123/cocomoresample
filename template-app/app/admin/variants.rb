module Variants
  class Load
    @@loaded_from_gem = false
    def self.is_loaded_from_gem
      @@loaded_from_gem
    end

    def self.loaded
    end

    # Check if this file is loaded from gem directory or not
    # The gem directory looks like
    # /template-app/.gems/gems/studio_store_ecommerce_[block_name]-0.0.[version]/app/admin/[admin_template].rb
    # if it has block's name in it then it's a gem
    @@loaded_from_gem = Load.method('loaded').source_location.first.include?('studio_store_ecommerce_')
  end

end

unless Variants::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockCatalogue::Variant, as: "Variant" do
    menu false

    actions :all, :except => [:show]
    permit_params :name, variant_properties_attributes: [:id, :name, :_destroy]
    remove_filter :images, :catalogue_variants, :catalogue_variant_properties

    batch_action :destroy, confirm: "Are you sure you want to delete these variants?" do |ids|
      if BxBlockCatalogue::Variant.where(id:ids).destroy_all
        flash[:notice]= "Successfully deleted #{ids.count} variants"
      else
        flash[:alert]= "Unable to delete variants"
      end
      redirect_to collection_path
    end

    form do |f|
      render partial: "admin/email_settings/description.html.erb",locals: { title: 'Add your products - Variants', subtitle: 'List all the variants of products you offer to your customers.' }
      f.inputs 'Variant Details' do
        f.input :name
        f.has_many :variant_properties, heading: 'Variants Attributes',allow_destroy: true,new_record: 'Add Variant Attribute' do |a|
          a.input :name, label: "Variant Attribute Name"
        end
      end
      f.actions do
        f.action :submit
      end
    end

    show do
      columns do
        column do
          panel 'Variant Detail' do
            table_for variant do
              column :name
              column :created_at
            end
            panel 'Variant Attributes' do
              table_for variant.variant_properties do
                column :name
                column :created_at
              end
            end
          end
        end
      end
    end

    member_action :get_attributes, method: :get do
      attributes = Variant.find(params[:variant_id]).variant_properties
      render json: { variant_properties: attributes }, status: 200
    end

    controller do
      def create
        super do
          if resource.valid?
            flash[:notice] = t('messages.success.created', resource: 'Variant')
            redirect_to admin_variants_url and return
          else
            flash.now[:error] = resource.errors.full_messages.to_sentence
            render action: 'new' and return
          end
        end
      end

      def update
        super do
          if resource.valid?
            flash[:notice] = t('messages.success.updated', resource: 'Variant')
            redirect_to edit_admin_variant_path(resource) and return
          else
            flash.now[:error] = resource.errors.full_messages.to_sentence
            render action: 'edit' and return
          end
        end
      end
    end

  end
end
