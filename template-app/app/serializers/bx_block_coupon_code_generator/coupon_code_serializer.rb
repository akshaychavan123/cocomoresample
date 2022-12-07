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
  class CouponCodeSerializer < BuilderBase::BaseSerializer
    attributes *[
        :id,
        :title,
        :description,
        :code,
        :discount_type,
        :discount,
        :valid_from,
        :valid_to,
        :min_cart_value,
        :max_cart_value,
        :created_at,
        :updated_at
    ]
  end
end
