module OnboardingSteps
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

unless OnboardingSteps::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockAdmin::OnboardingStep, as: "Onboarding Step" do
    menu false
    permit_params :title, :description, :step, :image, :step_completion, :onboarding_id
    config.sort_order = 'step_asc'

    actions :all, except: [:destroy]
    config.clear_action_items!

    index do
      selectable_column
      id_column
      column :title
      column :description
      column :image do |step|
        div :class => "cat_img" do
          image_tag(url_for(step.image)) if step.image.present?
        end
      end
      column :step_completion
      column :step
      actions
    end

    form do |f|
      f.inputs do
        f.input :title
        f.input :description
        f.input :image, :as => :file, :hint => f.object.image.present? ? image_tag(url_for(f.object.image)) : content_tag(:span, "120x120 resolution will be good")
        f.input :step_completion
        f.input :onboarding
      end
      f.actions
    end
  end
end
