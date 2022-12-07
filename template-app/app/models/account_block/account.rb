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
  class Account < AccountBlock::ApplicationRecord
    self.table_name = :accounts

    include Wisper::Publisher
    has_one_attached :image
    has_many :contacts, class_name: "BxBlockContactUs::Contact", dependent: :nullify
    has_many :orders, class_name: "BxBlockOrderManagement::Order", dependent: :destroy
    has_many :order_items, through: :orders, class_name: "BxBlockOrderManagement::OrderItem"
    has_many :order_transactions, class_name: "BxBlockOrderManagement::OrderTransaction", dependent: :nullify

    has_many :delivery_addresses, -> { order('created_at DESC') }, class_name: "BxBlockOrderManagement::DeliveryAddress", dependent: :destroy
    has_one :wishlist, class_name: "BxBlockWishlist::Wishlist", dependent: :destroy

    has_many :product_notifies, class_name: "BxBlockCatalogue::ProductNotify", dependent: :destroy

    has_many :reviews, class_name: "BxBlockCatalogue::Review", dependent: :destroy
    has_many :social_auths, class_name: "BxBlockSocialMediaAccount::SocialAuth", dependent: :destroy

    has_many :notifications, class_name: "BxBlockNotification::Notification", dependent: :destroy

    accepts_nested_attributes_for :delivery_addresses, :allow_destroy => true
    has_secure_password validations: false

    # has_many :attachments, -> {where record_type: 'AccountBlock::Account'}, class_name: "ActiveStorage::Attachment", dependent: :destroy, foreign_key: :record_id
    # -> { where a
    validates :full_name, presence: true
    validates :email, uniqueness: true
    # validates :user_name, presence: true, uniqueness: true
    # validates :password_digest, presence: true, uniqueness: true

    before_validation :parse_full_phone_number, if: -> {self.guest != true && self.full_phone_number.present? }

    after_create :track_event, :delete_guest_user
    before_destroy :remove_wishlists

    REGEX_PATTERN = /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/

    # def self.new_guest
    #   new { |u| u.guest = true }
    # end

    # def full_name
    #   guest ? "Guest" : username
    # end

    @@stripe_product_key = 'subscription_product_key'
    @@monthly_plan_key = 'monthly_plan_key'

    def self.stripe_product_key
      @@stripe_product_key
    end

    def self.monthly_plan_key
      @@monthly_plan_key
    end

    def track_event
      Analytics.track(user_id: ENV["HOST_URL"].split("-")[1],event: 'New Accounts Created')
    end

    def is_email_valid?
      self.email =~REGEX_PATTERN
    end

    private

    def delete_guest_user
      UpdateUserData.new({ uuid: uuid }, self).call if !guest && uuid.present?
      Account.where(guest: true).where('created_at <=  ?', Time.now - 24.hours).destroy_all # need to check on time
    end

    def parse_full_phone_number
      phone = Phonelib.parse(full_phone_number)
      self.full_phone_number = phone.sanitized
      self.country_code      = phone.country_code
      self.phone_number      = phone.raw_national
      errors.add(:full_phone_number, "Invalid Phone Number for UK or India") unless  self.country_code == 91 || self.country_code == 44
      valid_phone_number
    end

    def valid_phone_number
      unless Phonelib.valid?(full_phone_number)
        errors.add(:full_phone_number, "Invalid or Unrecognized Phone Number")
      end
    end

    def self.is_exists?(data)
      user = Account.find_or_initialize_by(email: data[:email])
      if (!user.new_record? && !user.social_auths.present?)
        return true
      else
        !user.present? || user&.new_record? || (!user&.new_record? && (user.social_auths&.pluck(:provider).include? data[:provider])) || (Account.exists?(user.id) && user.social_auths.present? && (user.social_auths&.pluck(:provider).exclude? data[:provider]))
      end
    end

    def remove_wishlists
      BxBlockWishlist::Wishlist.where(account_id: id).destroy_all
    end
  end
end
