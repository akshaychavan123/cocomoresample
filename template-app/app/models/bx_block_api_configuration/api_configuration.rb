module BxBlockApiConfiguration
  class ApiConfiguration < ApplicationRecord
    self.table_name = :api_configurations

    enum configuration_type: ['stripe', 'razorpay', 'shiprocket', '525k']

    validates :api_key, :api_secret_key, presence: true, if: -> {configuration_type == 'razorpay'}
    validates :api_key, :api_secret_key, presence: true, if: -> {configuration_type == 'stripe'}
    validates :ship_rocket_user_email, :ship_rocket_user_password, presence: true, if: -> {configuration_type == 'shiprocket'}
    validates :application_id, :application_token, presence: true, if: -> {configuration_type == 'bulkgate_sms'}
    validates :oauth_site_url, :base_url, :client_id, :client_secret, :logistic_api_key, presence: true, if: -> {configuration_type == '525k'}
    validates :configuration_type, uniqueness: true

    after_create :track_event
    after_commit :update_onboarding_step

    def track_event
      Analytics.track(user_id: ENV["HOST_URL"].split("-")[1],event: 'New Api Configuration Created')
    end

    def self.select_configuration_type
      event_names =  BxBlockApiConfiguration::ApiConfiguration.configuration_types.keys.to_a
      if BxBlockStoreProfile::BrandSetting.last&.country == "india"
        event_names.delete('stripe')
        event_names.delete('525k')
      else
        event_names.delete('razorpay')
        event_names.delete('shiprocket')
      end
      return event_names
    end

    private

    def update_onboarding_step
      step_update_service = BxBlockAdmin::UpdateStepCompletion.new('third_party_services', self.class.to_s)
      step_update_service.call
    end
  end
end
