# == Schema Information
#
# Table name: accounts
#
#  id                :bigint           not null, primary key
#  first_name        :string
#  last_name         :string
#  full_phone_number :string
#  country_code      :integer
#  phone_number      :bigint
#  email             :string
#  activated         :boolean          default(FALSE), not null
#  device_id         :string
#  unique_auth_id    :text
#  password_digest   :string
#  type              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
module AccountBlock
  class EmailAccount < Account
    include Wisper::Publisher
    include UrlUtilities
    EMAIL_REGEX = /[^@]+[@][\S]+[.][\S]+/.freeze

    has_secure_password
    validates :email, :format => { with: EMAIL_REGEX }, presence: true, uniqueness: true

    def change_email_keywords(content, email_otp=@email_otp, product=nil)
      default_email_setting = BxBlockSettings::DefaultEmailSetting.first
      BxBlockSettings::EmailSetting::CUSTOMER_EMAIL_KEYWORDS.each do |key|
        case  key
        when 'customer_email'
          content = content.gsub!("%{#{key}}", self&.email.to_s ) || content
        when 'customer_name'
          content = content.gsub!("%{#{key}}", self&.full_name.to_s ) || content
        when 'phone'
          content = content.gsub!("%{#{key}}", self&.full_name.to_s ) || content
        when 'otp'
          content = content.gsub!("%{#{key}}", email_otp&.pin.to_s) || content
        when 'brand_name'
          content = content.gsub!("%{#{key}}", default_email_setting&.brand_name.to_s ) || content
        when 'brand_logo'
          content = content.gsub!("%{#{key}}", "<div><img height='150px' src='#{url_for(default_email_setting&.logo)}'/></div>" ) || content
        when 'recipient_email'
          content = content.gsub!("%{#{key}}", default_email_setting&.contact_us_email_copy_to.to_s ) || content
        when 'product_name'
          content = content.gsub!("%{#{key}}", product&.name.to_s ) || content
        end
      end
      content
    end

    private
    def self.create_stripe_customers(account)
      stripe_customer = Stripe::Customer.create({
        email:  account.email
      })
      account.stripe_id = stripe_customer.id
      account.save
    end
  end
end
