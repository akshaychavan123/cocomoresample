module BxBlockOrderManagement
  class UpdateCartValueOnCatalogueUpdate
    attr_accessor :order_items

    def initialize(order_items)
      @order_items = order_items
    end

    def call
      update_order_items
    end

    def update_order_items
      order_items.each do |order_item|
        order = order_item.order
        if order_item.catalogue_variant_id.present?
          price = order_item.catalogue_variant.sale_price.present? ? order_item.catalogue_variant.sale_price : order_item.catalogue_variant.price
        else
          price = order_item.catalogue.sale_price.present? ? order_item.catalogue.sale_price : order_item.catalogue.price
        end
        total_amount = price - (0 * price) / order.sub_total
        gst_amount = (tax_percent = order_item.catalogue.tax&.tax_percentage.to_f) == 0 ? 0 : (((total_amount * tax_percent)/100) *100) / (100 + tax_percent)
        basic_amount = (total_amount - gst_amount)
        quantity = order_item.subscription_quantity || order_item.quantity || 0
        order_item.update_columns(unit_price: total_amount, total_price: (total_amount * order_item.order_item_qty), basic_amount: basic_amount, tax_amount: gst_amount)

        coupon = order.coupon_code
        if order.order_items.present? && coupon.present?
          BxBlockOrderManagement::ApplyCoupon.new(order, coupon, {cart_value: order.order_items.map(&:total_price).sum}).call
        end
        update_order_total(order)
        update_order_sub_total(order)
        order.save
        BxBlockCouponCodeGenerator::Validity.new(order_attributes(order), order.account).check_cart_total if coupon.present?
      end
    end

    private

    def order_attributes(order)
      { code: order.coupon_code.code, cart_id: order.id, cart_value: order.sub_total, existing_cart: true, is_release: true }
    end

    def update_order_total(order)
      if order.status == 'in_cart' || order.status == 'created'
        order.total = order.total_price
        order.total_after_shipping_charge
        order.total_after_tax_charge
      end
    end

    def update_order_sub_total(order)
      order.sub_total = order.sub_total_price if order.status == 'in_cart' || order.status == 'created'
    end
  end
end
