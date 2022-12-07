module AddressState
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

unless AddressState::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockOrderManagement::AddressState, as: "State" do
    menu false
    permit_params :name, :gst_code

    actions :all, except: [:destroy]
  end
end
