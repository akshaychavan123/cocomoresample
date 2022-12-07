module BxBlockSettings
  class EmailSetting < ApplicationRecord
    self.table_name = :email_settings
    #extend FriendlyId
    #friendly_id :title, use: %i[slugged finders]

    validates :title, presence: true, uniqueness: true
    validates :content, presence: true

    before_save :set_content
    after_create :track_create_event
    after_update :track_update_event
    after_commit :update_onboarding_step

    enum event_name: [ 'welcome email', 'new account otp verification', 'password changed', 'contact us', 'new order', 'order confirmed', 'order status', 'admin new order', 'product stock notification', 'order delivered', 'product low stock notification' ]

    ORDER_EMAIL_KEYWORDS = ['order_id', 'customer_name', 'billing_address', 'recipient_email', 'brand_name', 'brand_logo', 'shipping_address', 'order_status', 'order_summary']

    CUSTOMER_EMAIL_KEYWORDS = ['customer_name', 'customer_email', 'recipient_email', 'phone', 'otp', 'brand_name', 'brand_logo', 'billing_address', 'shipping_address', 'product_name']

    EMAIL_KEYWORDS = ['admin', 'customer_name', 'recipient_email', 'brand_logo', 'brand_name', 'contact_name', 'contact_phone', 'contact_email', 'query', 'product_name', 'product_qty']

    def should_generate_new_friendly_id?
      title_changed?
    end

    def track_create_event
      Analytics.track(user_id: ENV["HOST_URL"].split("-")[1],event: 'Create email setting Clicked')
    end

    def track_update_event
      Analytics.track(user_id: ENV["HOST_URL"].split("-")[1],event: 'Update Default email setting Clicked')
    end

    def set_content
      self.content = self.content.gsub("\"", "'")
    end

    def self.generate_email_template
      EmailSetting.event_names.each do |keyword|
        content = YAML.load_file("#{Rails.root}/config/templates.yaml")
        event_name = keyword[0].downcase.tr!(" ", "_")
        content = content[event_name]
        template = EmailSetting.find_or_initialize_by(event_name: keyword[0])
        template.title = keyword[0]
        template.content = content
        template.save
      end
    end

    private

    def update_onboarding_step
      step_update_service = BxBlockAdmin::UpdateStepCompletion.new('email', self.class.to_s)
      step_update_service.call
    end
  end
end
