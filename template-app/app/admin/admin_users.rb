module AdminUsers
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

unless AdminUsers::Load.is_loaded_from_gem
  ActiveAdmin.register AdminUser do
    menu false
    permit_params :email, :password, :password_confirmation
    actions :all, except: [:new, :destroy]

    index do
      selectable_column
      id_column
      column :email
      column :created_at
      actions
    end

    show do
      attributes_table do
        row :email
        row :created_at
        row :updated_at
      end
    end

    filter :email
    filter :created_at

    form do |f|
      f.inputs do
        f.input :email
        f.input :password
        f.input :password_confirmation
      end
      f.actions
    end

  end
end
