module Taxes
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

unless Taxes::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockOrderManagement::Tax, as: "Tax" do
    menu false
    permit_params :tax_percentage
    actions :all, :except => [:destroy, :edit]

    # controller do
    #   def action_methods
    #     if BxBlockOrderManagement::Tax.first.present?
    #       super - ['new']
    #     else
    #       super
    #     end
    #   end
    # end

    index :download_links => false do
      selectable_column
      column :tax_percentage
      actions
    end

    form do |f|
      render partial: "admin/email_settings/description.html.erb",locals: { title: 'Set up your business - Taxes', subtitle: 'Which sales tax needs to be applied to your products?' }
      f.inputs 'Customer Details' do
        f.input :tax_percentage
      end
      f.actions do
        f.action :submit, label: f.object.new_record? ? 'Create Tax' : 'Update Tax'
        f.cancel_link(action: 'index')
      end
    end

    show do
      panel 'Tax Details' do
        table_for tax do
          column :tax_percentage
          column :created_at
          column :updated_at
        end
      end
    end

  end
end
