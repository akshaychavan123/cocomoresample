module Banners
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

unless Banners::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockBanner::Banner, as: "App Banners" do
    menu false
    permit_params :banner_position,:web_banner,
    attachments_attributes: [
      :id,
      :image,
      :position,
      :title,
      :subtitle,
      :url,
      :url_type,
      :url_id,
      :category_url_id,
      :_destroy
    ]
    remove_filter :attachments
    config.sort_order = "banner_position_desc"
    config.batch_actions = false

    index do
      selectable_column
      id_column
      column :banner_position
      column :created_at
      column :updated_at
      actions
    end

    show do |banner|
      attributes_table do
        row :banner_position
        row :created_at
        row :updated_at
      end
    end

    form do |f|
      render partial: "admin/email_settings/description.html.erb",locals: { title: 'Create your store - App banner', subtitle: "Add a app banner - this will go on your app's home page." }
      f.inputs do
        f.input :banner_position
        f.has_many :attachments, as: :attachable, heading: 'Banner Images',allow_destroy: true,new_record: 'Add Image', class: "banner_image" do |i|
          i.input :position
          i.input :image, as: :file, hint: i.object.image.present? ? image_tag(i.object.image, :size => "260x180") : content_tag(:span, '374*107 resolution will be good'), input_html: { class: 'image banner-image' }
          i.input :url
          i.input :url_type, as: :select, collection: ['product', 'category'],allow_blank: false, input_html: {class: 'url_type' }
          i.input :category_url_id, as: :select, collection: BxBlockCategoriesSubCategories::Category.all.map { |u| [u.name, u.id] }, include_blank: false, allow_blank: false, input_html: {class: 'url_id2 select2', disabled: true }, label: 'Select Category'
          i.input :url_id, as: :select, collection: BxBlockCatalogue::Catalogue.active.map { |u| [u.name, u.id] }, include_blank: false, allow_blank: false, input_html: {class: 'url_id1 select2' , disabled: true}, label: 'Select Product'
        end
      end
      f.actions
    end

    controller do
      def create
        super do
          if resource.valid?
            if resource.attachments.present?
              resource.attachments.each do |attachment|
                attachment.update_column(:url_id, nil) unless attachment.url_type.present?
                attachment.update_column(:category_url_id, nil) unless attachment.url_type.present?
              end
            end
            flash[:notice] = t('messages.success.created', resource: 'Banner')
            redirect_to admin_app_banners_url and return
          else
            flash.now[:error] = "#{resource.errors.full_messages.to_sentence}"
            render action: 'edit' and return
          end
        end
      end

      def update
        super do
          if resource.valid?
            if resource.attachments.present?
              resource.attachments.each do |attachment|
                attachment.update_column(:url_id, nil) unless attachment.url_type.present?
                attachment.update_column(:category_url_id, nil) unless attachment.url_type.present?
              end
            end
            flash[:notice] = t('messages.success.updated', resource: 'Banner')
            redirect_to edit_admin_app_banner_path(resource) and return
          else
            flash.now[:error] = "#{resource.errors.full_messages.to_sentence}"
            render action: 'edit' and return
          end
        end
      end

      def destroy
        super do
          flash[:notice] = t('messages.success.deleted', resource: 'Banner')
          redirect_to(admin_app_banners_url) and return
        end
      end
    end

    controller do
      def scoped_collection
        super.where(web_banner: false)
      end
    end
  end
end
