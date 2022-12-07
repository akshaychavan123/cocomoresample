module BxBlockCart
  class CartSerializer < BuilderBase::BaseSerializer

    attributes *[
      :id, :amount, :coupon_code_id, :sub_total, :total, :applied_discount, :delivery_charges,
      :payment_failed_at, :delivery_error_message, :shipping_total, :total_tax, :updated_at
    ]

    attribute :order_items do |object, params|
      if object.present?
        BxBlockOrderManagement::OrderItemSerializer.new(
          object.order_items.latest_first, { params: params }
        ).serializable_hash[:data]
      end
    end

    attribute :coupon do |object|
      if object.present?

        BxBlockCouponCodeGenerator::CouponCodeSerializer.new(object.coupon_code).serializable_hash[:data]
      end
    end

    attribute :account do |object|
      if object.present?

        AccountBlock::AccountSerializer.new(object.account).serializable_hash[:data]
      end
    end

    attribute :total do |object|
      object.total&.round(2)
    end
  end
end
