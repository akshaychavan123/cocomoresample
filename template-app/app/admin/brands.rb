module Brands
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

unless Brands::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockCatalogue::Brand, as: "Brands" do
    menu false
    permit_params :name

    index do
      selectable_column
      id_column
      column :name
      column :created_at
      column :updated_at
      actions
    end

    show do
      attributes_table do
        row :name
        row :created_at
        row :updated_at
      end
    end

    form do |f|
      render partial: "admin/email_settings/description.html.erb",locals: { title: 'Add your products - Brands', subtitle: 'List all the brands of products you offer your customers.' }
      f.inputs do
        f.input :name
      end
      f.actions
    end

  end
end