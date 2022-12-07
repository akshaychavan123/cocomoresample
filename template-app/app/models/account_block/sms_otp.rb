# == Schema Information
#
# Table name: sms_otps
#
#  id                :bigint           not null, primary key
#  full_phone_number :string
#  pin               :integer
#  activated         :boolean          default(FALSE), not null
#  valid_until       :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
module AccountBlock
  class SmsOtp < ApplicationRecord
    self.table_name = :sms_otps

    include Wisper::Publisher

    before_validation :parse_full_phone_number

    before_save :generate_pin_and_valid_date

    validate :valid_phone_number
    validates :full_phone_number, presence: true

    attr_reader :phone

    def generate_pin_and_valid_date
      self.pin         = rand(1_0000..9_9999)
      self.valid_until = Time.current + 5.minutes
    end

    def send_pin_via_sms(text_message = "")
      message = text_message.gsub("<sms_pin>","#{self.pin}")
      txt     =  BulkgateTextMessage.new(self.full_phone_number, message)
      txt.call
    end

    private

    def parse_full_phone_number
      @phone = Phonelib.parse(full_phone_number)
      errors.add(:full_phone_number, "Invalid Phone Number for UK or India") unless  @phone.country_code == "91" || @phone.country_code == "44"
      self.full_phone_number = @phone.sanitized
    end

    def valid_phone_number
      unless Phonelib.valid?(full_phone_number)
        errors.add(:full_phone_number, "Invalid or Unrecognized Phone Number")
      end
    end
  end
end
