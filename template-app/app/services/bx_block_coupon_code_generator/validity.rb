module BxBlockCouponCodeGenerator
  class Validity
    attr_accessor :params, :coupon_code, :cart_value, :order, :user

    def initialize(params, user)
      @params       =   params
      @coupon_code  =   CouponCode.find_by_code(params[:code])
      @order        =   BxBlockOrderManagement::Order.find(params[:cart_id])
      @cart_value   =   params[:cart_value].to_f
      @user         =   user
      @is_release   =   params[:is_release]
    end

    def check_cart_total
      return if @is_release
      if coupon_code.min_cart_value && cart_value < coupon_code.min_cart_value
        respond_error('min')
      elsif coupon_code.max_cart_value && cart_value > coupon_code.max_cart_value
        respond_error('max')
      else
        calculate_discount
      end
    end

    def calculate_discount
      discount = coupon_code.discount_type == "percentage" ? ((cart_value * coupon_code.discount) / 100) : coupon_code.discount
      discount_price = (cart_value - discount)&.round(2)
      shipping_charges = order.shipping_total.to_f
      tax_charges = order.total_tax.to_f
      order.update!(coupon_code_id: coupon_code.id, total: (discount_price + shipping_charges + tax_charges), applied_discount: discount)
      return OpenStruct.new(success?: true, data: { coupon: coupon_code, actual_price: cart_value, discount_type: coupon_code.discount_type, cart_discount: coupon_code.discount, discount_price: discount, after_discount_price: discount_price }, msg: 'Coupon applied successfully', code: 200)
    end

    def respond_error(value)
      if value == 'min'
        min_cart_error
      else
        max_cart_error
      end
    end

    def min_cart_error
      if params[:existing_cart] == true
        remove_coupon
        return OpenStruct.new(success?: false, data: nil, msg: 'Your coupon has been removed due to min cart limit', code: 208)
      else
        return OpenStruct.new(success?: false, data: nil, msg: 'Please add few more product(s) to apply this coupon', code: 208)
      end
    end

    def max_cart_error
      if params[:existing_cart] == true
        remove_coupon
        return OpenStruct.new(success?: false, data: nil, msg: 'Your coupon has been removed due to max cart limit', code: 208)
      else
        return OpenStruct.new(success?: false, data: nil, msg: 'Your cart amount is exceeding the limit value. Please check coupon desctiption', code: 208)
      end
    end

    def remove_coupon
      order.update!(coupon_code_id: nil, applied_discount: 0)
      shipping_charges = order.shipping_total.to_f
      tax_charges = order.total_tax.to_f
      order.update!(total: (cart_value + shipping_charges + tax_charges), sub_total: order.total_price)
    end

  end
end
