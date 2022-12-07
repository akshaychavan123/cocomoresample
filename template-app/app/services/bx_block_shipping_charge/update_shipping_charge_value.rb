module BxBlockShippingCharge
  class UpdateShippingChargeValue
    attr_accessor :order, :zipcode, :params, :is_success
    def initialize(params)
      @params = params
      @order  = BxBlockOrderManagement::Order.find_by(id: params[:cart_id])
      @is_success = false
    end

    def call
      save_order
    end

    def save_order
      update_order_total
      update_order_sub_total
      order.save
      if is_success
        Success.new({ order: order}, 'Updated shipping charge value successfully', 200)
      else
        Error.new({ order: order}, "Sorry, currently delivery is not available for this location.", 208)
      end
    end

    private

    def update_order_total
      order.total = order.total_price
      total_after_shipping_charge
      order.total_after_tax_charge
    end

    def update_order_sub_total
      order.sub_total = order.sub_total_price
    end

    def total_after_shipping_charge
      zipcode = BxBlockZipcode::Zipcode.find_by_code(params[:zipcode])
      applied_shipping_charge = BxBlockShippingCharge::ShippingCharge.last
      if zipcode.present? && zipcode.activated
        charge = zipcode.charge
        order.shipping_charge = charge
        unless order.total <= zipcode.price_less_than
          order.shipping_discount = charge
        else
          order.shipping_discount = 0.0
        end
        @is_success = true
      else
        if applied_shipping_charge.present?
          default_charge = applied_shipping_charge.charge
          order.shipping_charge = default_charge
          unless order.total <= applied_shipping_charge.below
            order.shipping_discount = default_charge
          else
            order.shipping_discount = 0.0
          end
        else
          order.shipping_charge = 0.0
          order.shipping_discount = 0.0
        end
        @is_success = false
      end
      order.shipping_total = order.shipping_charge - order.shipping_discount
      order.shipping_net_amt = order.shipping_charge - order.shipping_discount
      order.total = order.total + order.shipping_total
    end
  end
end
