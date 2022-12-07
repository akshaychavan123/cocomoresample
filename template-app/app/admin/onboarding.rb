module Onboarding
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

unless Onboarding::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockAdmin::Onboarding, as: "Onboarding" do
    menu false
    permit_params :title, :description

    actions :all, except: [:destroy]
    config.clear_action_items!

    index do
      selectable_column
      id_column
      column :title
      column :description
      column "Steps" do |onboarding|
        div(:class => "table_actions") do
          link_to("Steps", admin_onboarding_steps_path, class: 'member_link')
        end
      end
      actions
    end

    form do |f|
      f.inputs do
        f.input :title
        f.input :description
      end
      f.actions
    end
  end
end