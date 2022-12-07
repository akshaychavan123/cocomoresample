module ApiConfigurations
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

unless ApiConfigurations::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockApiConfiguration::ApiConfiguration, as: 'Partner Configuration' do
    actions :all, except: :new
    menu false
    permit_params :api_key, :api_secret_key, :configuration_type, :ship_rocket_base_url, :ship_rocket_user_email, :ship_rocket_user_password, :application_id, :application_token, :oauth_site_url, :base_url, :client_id, :client_secret, :logistic_api_key
    form do |f|
      render partial: "admin/email_settings/description.html.erb",locals: { title: 'Set up your business - Third-party intergrations', subtitle: 'Add credentials to integrate third-party services (eg Payments, Logistics, SMS).' }

      f.inputs do
        if f.object.new_record?
          f.input :configuration_type, as: :select, collection: BxBlockApiConfiguration::ApiConfiguration.select_configuration_type, include_blank: true, allow_blank: false, :prompt => "Select Type", input_html: {class: 'configuration_type'}
        else
          f.input :configuration_type, as: :select, collection: BxBlockApiConfiguration::ApiConfiguration.select_configuration_type, include_blank: true, allow_blank: false, :prompt => "Select Type", input_html: {class: 'configuration_type', disabled: true}
        end
        if f.object.configuration_type == 'razorpay'
          f.input :api_key, label: 'Api Key', input_html: { class: 'api_key hide' },
                  :hint => content_tag(:a, "Where to find?", href: "https://docs.google.com/document/d/1IXKNBx5xWoS00oy019gW_cPLSfrl7F0JkYsqMU-Mw1k/edit?usp=sharing", target: :blank)
          f.input :api_secret_key, label: 'Secret Api key', input_html: { class: 'api_key hide' },
                  :hint => content_tag(:a, "Where to find?", href: "https://docs.google.com/document/d/1IXKNBx5xWoS00oy019gW_cPLSfrl7F0JkYsqMU-Mw1k/edit?usp=sharing", target: :blank)
        elsif f.object.configuration_type == 'shiprocket'
          f.input :ship_rocket_user_email, label: 'Ship rocket user email'
          f.input :ship_rocket_user_password, label: 'Ship rocket user password', input_html: {type: "text", value: f.object.ship_rocket_user_password}
        elsif f.object.configuration_type == 'bulkgate_sms'
          f.input :application_id, label: 'bulkgate application id', input_html: {class: 'bulkgate_fields hide'}
          f.input :application_token, label: 'bulkgate application id token', input_html: {class: 'bulkgate_fields hide'}
        elsif f.object.configuration_type == '525k'
          f.input :oauth_site_url, input_html: {class: 'logistic_keys hide'}
          f.input :base_url, input_html: {class: 'logistic_keys hide'}
          f.input :client_id, input_html: {class: 'logistic_keys hide'}
          f.input :client_secret, input_html: {class: 'logistic_keys hide'}
          f.input :logistic_api_key, input_html: {class: 'logistic_keys hide'}
        end
      end
      f.actions
    end

    controller do
      def index
        if ENV['RAZORPAY_ACCOUNT_ID'].present?
          begin
            url = URI("https://staging.cloud-marketplace.builder.ai/api/accounts/#{ENV['RAZORPAY_ACCOUNT_ID']}")
            http = Net::HTTP.new(url.host, url.port);
            http.use_ssl = true
            request = Net::HTTP::Get.new(url)
            request.basic_auth 'local_cat', 'password'
            response = http.request request
            @live_status = JSON.parse(response.body)["data"]["status"]
          rescue
            @live_status = "API got error"
          ensure
            super
          end
        else
          super
        end
      end

      def create
        super do
          if resource.valid?
            flash[:notice] = t('messages.success.created', resource: 'Product')
            redirect_to admin_api_configurations_url and return
          else
            flash.now[:error] = resource.errors.full_messages.to_sentence
            render action: 'new' and return
          end
        end
      end
    end

    index do
      selectable_column
      column :partner do |api|
        api.configuration_type.capitalize
      end
      column :user_name do |user|
        if user.configuration_type == "razorpay"
          ENV['RAZORPAY_KEY'] || user.api_key
        else
          user.ship_rocket_user_email
        end
      end
      column :password do |pass|
        render partial: "password_api", locals: { pass: pass }
      end
      column :kyc_status do |state|
        render partial: "status_api", locals: {state: state}
      end
      actions
    end

  end
end
