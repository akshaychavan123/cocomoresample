module BxBlockOrderManagement
  class UpdateCartValue
    attr_accessor :order, :is_release

    def initialize(order, user, is_release=false)
      @order  =   order
      @user   =   user
      @is_release = is_release
    end

    def call
      save_order
      BxBlockCouponCodeGenerator::Validity.new(order_attributes, @user).check_cart_total if order.coupon_code.present?
    end

    def save_order
      update_order_total
      update_order_sub_total
      if order.save
        unless is_release
          order.order_items.each do |order_item|
            if order_item.catalogue_variant_id.present?
              price = order_item.catalogue_variant.sale_price.present? ? order_item.catalogue_variant.sale_price : order_item.catalogue_variant.price
              tax = order_item.catalogue_variant.tax
            else
              price = order_item.catalogue.sale_price.present? ? order_item.catalogue.sale_price : order_item.catalogue.price
              tax = order_item.catalogue.tax
            end
            total_amount = price - (0 * price) / order.sub_total

            gst_amount = (tax_percent = tax&.tax_percentage.to_f) == 0 ? 0 : (((total_amount * tax_percent)/100) *100) / (100 + tax_percent)
            basic_amount = (total_amount - gst_amount)
            quantity = order_item.subscription_quantity || order_item.quantity || 0
            order_item.update_columns(unit_price: total_amount, total_price: (total_amount * order_item.order_item_qty), basic_amount: basic_amount, tax_amount: gst_amount)
          end
          coupon = order.coupon_code
          if order.order_items.present? && coupon.present?
            BxBlockOrderManagement::ApplyCoupon.new(order, coupon, {cart_value: recalculate_cart_value(order)}).call
          end
        end
      end
    end

    private

    def order_attributes
      { code: order.coupon_code.code, cart_id: order.id, cart_value: recalculate_cart_value(order), existing_cart: true }
    end

    def update_order_total
      if order.status == 'in_cart' || order.status == 'created'
        order.total = order.total_price(is_release)
        order.total_after_shipping_charge
        order.total_after_tax_charge
      end
    end

    def update_order_sub_total
      order.sub_total = order.sub_total_price
    end

    def recalculate_cart_value(order)
      total = 0.0
      order.order_items.each do |order_item|
        if order_item.catalogue_variant_id.present?
          price = order_item.catalogue_variant.on_sale? ? order_item.catalogue_variant.sale_price : order_item.catalogue_variant.price
        else
          price = order_item.catalogue.on_sale? ? order_item.catalogue.sale_price : order_item.catalogue.price
        end
        total = total + (price.to_f * order_item.quantity.to_i)
      end
      total
    end
  end
end
