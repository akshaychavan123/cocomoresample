module ShippingCharge
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

unless ShippingCharge::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockShippingCharge::ShippingCharge, as: "ShippingCharge" do
    menu false

    actions :all, :except => [:show]

    controller do
      def action_methods
        if BxBlockShippingCharge::ShippingCharge.first.present?
          super - ['new']
        else
          super
        end
      end
    end

    action_item :zipcodes do
      link_to 'Zipcodes', admin_zipcodes_path
    end unless config.action_items.map(&:name).include?(:zipcodes)

    permit_params :below, :charge

    index :download_links => false do
      column "Less Than", :below
      column :charge
      actions

    end

    filter :below, label: "Less Than"
    filter :charge


    form do |f|
      f.inputs 'Shipping Charge' do
        f.input :below, label: 'Less Than', hint: self.object.below.present? ? "above #{self.object.below} delivery charges will be free" : "above this amount delivery charges will be free"
        f.input :charge
        actions
      end
    end

    show do
      attributes_table do
        row 'Less Than' do |sc|
          sc.below
        end
        row :charge
      end
    end
  end
end
