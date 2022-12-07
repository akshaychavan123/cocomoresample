module ContactUs
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

unless ContactUs::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockContactUs::Contact, as: "ContactUs" do
    menu false
    actions :index, :show, :destroy

    index :download_links => false do
      column :name
      column :email
      column :phone_number
      column :description
      # column :purpose_of_contact
      column :created_at
      column :customer do |cu|
        if cu&.account.present?
          if cu&.account&.guest == true
            link_to cu&.account&.email, "#"
          else
            link_to cu&.account&.full_name, admin_account_path(cu&.account&.id)
          end
        else
          link_to 'Guest', "#"
        end
      end
      actions
    end

    show do
      attributes_table do
        row :account do |cu|
          if cu&.account.present?
            if cu&.account&.guest == true
              link_to cu&.account&.email, "#"
            else
              link_to cu&.account&.full_name, admin_account_path(cu&.account&.id)
            end
          else
            link_to 'Guest', "#"
          end
        end
        row :name
        row :email
        row :phone_number
        row :description
        # row :purpose_of_contact
        row :created_at
        row :updated_at
      end
    end
  end
end