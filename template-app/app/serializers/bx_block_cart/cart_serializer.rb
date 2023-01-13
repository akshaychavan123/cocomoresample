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

    attribute :items_total do |object|
      object.items_total
    end

    attribute :is_delivery_available do |object|
      @delivery_address = object.delivery_addresses.where(address_for: ['billing_and_shipping', 'shipping']).first
      if @delivery_address.present?
        BxBlockZipcode::Zipcode.activated.find_by(code: @delivery_address.zip_code).present?
      else
        true
      end
    end

    attribute :shipping_cost do |object|
      @delivery_address = object.delivery_addresses.where(address_for: ['billing_and_shipping', 'shipping']).first
      if @delivery_address.present?
        BxBlockZipcode::Zipcode.activated.find_by(code: @delivery_address.zip_code)&.charge.to_f
      else
        BxBlockShippingCharge::ShippingCharge.last&.charge.to_f
      end
    end

    attribute :is_delivery_free do |object|
      object.shipping_total.to_f > 0 ? false : true
    end

    attribute :delivery_address do |object|
      if object.delivery_address_orders.present?
        delivery_address_order = object.delivery_address_orders.joins(:delivery_address).where("delivery_addresses.address_for IN (?) ", ['shipping','billing_and_shipping']).last
        delivery_address_order&.delivery_address if delivery_address_order.present?
      end
    end

  end
end
