module BxBlockOrderManagement
  class ApplyCoupon

    attr_accessor :coupon_code, :order, :cart_value

    def initialize(order, coupon, params)
      #CouponCode.find_by_code(params[:code])
      #BxBlockOrderManagement::Order.find(params[:cart_id])
      @coupon_code  =   coupon
      @order        =   order
      @cart_value   =   params[:cart_value].to_i || @order.sub_total
    end

    def call
      discount = coupon_code.discount_type == "percentage" ? ((cart_value * coupon_code.discount) / 100) : coupon_code.discount
      if cart_value < coupon_code.min_cart_value
        return OpenStruct.new(success?: false, msg: "Please add few more product(s) to apply this coupon", code: 400)
      elsif cart_value > coupon_code.max_cart_value
        return OpenStruct.new(success?: false, msg: 'Your cart amount is exceeding the coupon limit', code: 400)
      elsif coupon_code.valid_to&.< Date.today
        return OpenStruct.new(success?: false, msg: 'Coupon code is expired', code: 400)
      elsif discount.present? && cart_value.present? && (discount.to_f > cart_value.to_f)
        return OpenStruct.new(success?: false, msg: 'Coupon amount is more than cart amount', code: 400)
      else
        discount_price = (cart_value - discount)&.round(2)
        shipping_charges = order.shipping_total.to_f
        tax_charges = order.total_tax.to_f
        order.update!(coupon_code_id: coupon_code.id, sub_total: discount_price, total: (discount_price + shipping_charges), applied_discount: discount)
        order.order_items.each do |order_item|
          if order_item.catalogue_variant_id.present?
            price = order_item.catalogue_variant.sale_price.present? ? order_item.catalogue_variant.sale_price : order_item.catalogue_variant.price
            tax = order_item.catalogue_variant.tax
          else
            price = order_item.catalogue.sale_price.present? ? order_item.catalogue.sale_price : order_item.catalogue.price
            tax = order_item.catalogue.tax
          end
          total_amount = price - (discount * price) / cart_value
          gst_amount = (((total_amount * tax&.tax_percentage.to_f)/100) *100) / (100+tax&.tax_percentage.to_f)
          basic_amount = (total_amount - gst_amount)
          order_item.update_columns(unit_price: total_amount, total_price: (total_amount * order_item.order_item_qty), basic_amount: basic_amount.to_f.round(2), tax_amount: gst_amount.to_f.round(2))
        end
        order.update_column('total_tax', order.order_items.map(&:tax_charge).compact.sum.round(2))
        delivery_address = order.delivery_addresses.where(address_for: ['billing_and_shipping', 'shipping']).first
        if delivery_address.present?
          BxBlockShippingCharge::UpdateShippingChargeValue.new({cart_id: order.id, zipcode: delivery_address.zip_code}).call
        end
        return OpenStruct.new(success?: true, order: order,  msg: 'Coupon applied successfully', code: 200)
      end
    end
  end
end
