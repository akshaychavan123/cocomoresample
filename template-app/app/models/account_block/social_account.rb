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
  class SocialAccount < Account
    include Wisper::Publisher

    has_secure_password :validations => false
    # validates :email, uniqueness: true, presence: true, if: ->(obj){obj.email.present? }
    validates :unique_auth_id, presence: true

    after_validation :set_active

    def set_active
      self.activated = true
    end
  end
end
