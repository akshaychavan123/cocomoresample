# == Schema Information
#
# Table name: coupon_codes
#
#  id             :bigint           not null, primary key
#  title          :string
#  description    :string
#  code           :string
#  discount_type  :string           default("flat")
#  discount       :decimal(, )
#  valid_from     :datetime
#  valid_to       :datetime
#  min_cart_value :decimal(, )
#  max_cart_value :decimal(, )
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
module BxBlockCouponCodeGenerator
  class CouponCode < BxBlockCouponCodeGenerator::ApplicationRecord
    self.table_name = :coupon_codes

    #has_many :orders, class_name: "BxBlockOrderManagement::Order"

    DISCOUNT_TYPE = {
        flat: 'flat',
        percentage: 'percentage'
    }.freeze

    MAX_CART_VALUE = 100_000
    MAX_DISCOUNT_VALUE = 100_000

    validates :title, length: { maximum: 50 }, presence: true
    validates :description, length: { maximum: 200 }
    validates :code, length: { maximum: 50 }, presence: true
    validates :code, uniqueness: true

    validates :discount_type, acceptance: {
        accept: [DISCOUNT_TYPE[:flat], DISCOUNT_TYPE[:percentage]]
    }
    validate :min_cart_value_not_negative
    validate :max_cart_value_less_max_value
    validate :min_cart_value_less_max_cart_value
    validate :discount_value
    validate :coupon_code_date_greater_than_today
    validate :coupon_code_date_validity

    validates_presence_of :description, :discount_type, :discount, :valid_from, :valid_to,
                          :min_cart_value, :max_cart_value

    before_create :track_event

    def track_event
      Analytics.track(user_id: ENV["HOST_URL"].split("-")[1],event: 'New Coupon Created')
    end

    def min_cart_value_not_negative
      if min_cart_value&.negative?
        errors.add(:min_cart_value, "Can't be less than zero")
      end
    end

    def max_cart_value_less_max_value
      if max_cart_value&.>(MAX_CART_VALUE)
        errors.add(:max_cart_value, "Can't be more than #{MAX_CART_VALUE}")
      end
    end

    def min_cart_value_less_max_cart_value
      if min_cart_value&.> max_cart_value
        errors.add(:min_cart_value, "Can't be more than #{max_cart_value}")
      end
    end

    def discount_value
      if discount&.negative? || discount&.>(MAX_DISCOUNT_VALUE)
        errors.add(:discount, 'Discount value is out of bounds')
      end
    end

    def coupon_code_date_validity
      if valid_to&.< valid_from
        errors.add(:valid_to, "Can't be less than valid from date")
      end
    end

    def coupon_code_date_greater_than_today
      unless valid_from&.>= Date.today
        errors.add(:valid_from, 'Should not be a past date')
      end
    end
  end
end
