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
  class SmsOtpSerializer < BuilderBase::BaseSerializer
    attributes :full_phone_number, :activated, :pin, :created_at, :valid_until, :full_name
  end
end
