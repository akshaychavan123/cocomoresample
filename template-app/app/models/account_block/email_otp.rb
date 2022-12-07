# == Schema Information
#
# Table name: email_otps
#
#  id          :bigint           not null, primary key
#  email       :string
#  pin         :integer
#  activated   :boolean          default(FALSE), not null
#  valid_until :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
module AccountBlock
  class EmailOtp < ApplicationRecord
    include Wisper::Publisher
    include UrlUtilities

    self.table_name = :email_otps

    EMAIL_REGEX = /[^@]+[@][\S]+[.][\S]+/.freeze

    validate :valid_email
    validate :valid_phone_number
    validates :email, :format => { with: EMAIL_REGEX }, presence: true

    before_save :generate_pin_and_valid_date
    before_validation :parse_full_phone_number
    after_save :send_email

    attr_reader :phone

    def change_email_keywords(content, email_otp, product=nil)
      default_email_setting = BxBlockSettings::DefaultEmailSetting.first
      BxBlockSettings::EmailSetting::CUSTOMER_EMAIL_KEYWORDS.each do |key|
        case  key
        when 'customer_email'
          content = content.gsub!("%{#{key}}", self&.email.to_s ) || content
        when 'customer_name'
          content = content.gsub!("%{#{key}}", self&.full_name.to_s ) || content
        when 'phone'
          content = content.gsub!("%{#{key}}", self&.email.to_s ) || content
        when 'otp'
          content = content.gsub!("%{#{key}}", email_otp.pin.to_s) || content
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

    def send_email
      unless self.activated
        # EmailOtpMailer
        #   .with(otp: self)
        #   .otp_email.deliver
      end
    end

    def generate_pin_and_valid_date
      self.pin         = rand(1_0000..9_9999)
      self.valid_until = Time.current + 5.minutes
    end

    private

    def valid_email
      unless email =~ URI::MailTo::EMAIL_REGEXP
        errors.add(:email, "Invalid email format")
      end
    end

    def valid_phone_number
      if phone_number.present? && (Account.exists? phone_number: phone_number) && (Account.find_by(phone_number: phone_number)&.email.to_s != self.email)
        errors.add :phone_number, 'Phone number has already been taken'
      end
    end

    def parse_full_phone_number
      phone = Phonelib.parse(phone_number)
      self.phone_number      = phone.raw_national
    end
  end
end
