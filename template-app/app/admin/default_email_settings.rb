module DefaultEmailSettings
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

unless DefaultEmailSettings::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockSettings::DefaultEmailSetting, as: "DefaultEmailSetting" do
    menu false
    permit_params :brand_name, :logo, :from_email, :recipient_email, :contact_us_email_copy_to, :send_email_copy_method

    action_item :email_setting do
      link_to 'Email Templates', admin_email_settings_path
    end unless config.action_items.map(&:name).include?(:email_setting)

    controller do
      def action_methods
        if BxBlockSettings::DefaultEmailSetting.first.present?
          super - ['new']
        else
          super
        end
      end
    end

    form do |f|
      f.inputs 'Email Setting Details'  do
        f.input :brand_name
        f.input :recipient_email, label: 'Send Order Email Copy To'
        f.input :contact_us_email_copy_to, label: 'Send Contact Us Email Copy To'
        f.input :send_email_copy_method, label: 'Send Email Copy Method', as: :select, collection: BxBlockSettings::DefaultEmailSetting::EMAIL_COPY_METHODS, include_blank: true, prompt: 'Select method'
        f.input :logo, :as => :file, :hint => f.object.logo.present? ? image_tag(url_for(f.object.logo)) : content_tag(:span, "please upload image")
      end
      f.actions do
        f.action :submit
        f.cancel_link(action: 'index')
      end
    end

    controller do

      def update
        super do
          if resource.valid?
            flash[:notice] = 'Default email settings updated successfully.'
            redirect_to edit_admin_default_email_setting_path(resource) and return
          else
            render :edit and return
          end
        end
      end

    end

  end
end
