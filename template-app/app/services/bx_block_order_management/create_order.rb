module BxBlockOrderManagement
  class CreateOrder
    attr_accessor :order, :is_gift, :schedule_time, :order_items

    def initialize(params)
      @order = BxBlockOrderManagement::Order.find(params[:cart_id])
      @is_gift = params[:is_gift]
      @source = 'cod'
      @schedule_time = params[:schedule_time]
      @order_items =  @order.order_items
    end

    def call
      if order.nil?
        return OpenStruct.new(success?: false, msg: 'Cannot find the order', code: 400)
      elsif check_order_status
        return OpenStruct.new(success?: false, msg: 'Payment not done for this order', code: 400)
      elsif check_valid_items
        return OpenStruct.new(success?: false, msg: 'No item found in the cart', code: 400)
      elsif product_not_available?
        return OpenStruct.new(success?: false, msg: 'Item not available', code: 400)
      else
        update_order
        return OpenStruct.new(success?: true, order: order,  msg: 'Congratulations, Order placed successfully', code: 200)
      end
    end

    private

    def check_order_status
      !(['in_cart', 'created', 'payment_failed', 'payment_pending'].include? order.status)
    end

    def check_valid_items
      !(order_items.present?)
    end

    def update_order
      order.place_order!
      order.update!(order_date: Time.current,
                    is_gift: is_gift == true,
                    source: @source,
                    schedule_time: schedule_time)
    end

    def product_not_available?
      result = false
      if order_items.present?
        order_items.map do |order_item|
          quantity = order_item.quantity.to_i
          if order.is_blocked?
            if order_item.catalogue_variant.present?
              result ||= order_item.quantity.to_i > ((order_item.catalogue_variant.stock_qty.to_i - order_item.catalogue_variant.block_qty.to_i || 0) + order_item.quantity.to_i)
            else
              result ||= order_item.quantity.to_i > ((order_item.catalogue.stock_qty.to_i - order_item.catalogue.block_qty.to_i || 0) + order_item.quantity.to_i)
            end
          else
            if order_item.catalogue_variant.present?
              result ||= order_item.quantity.to_i > (order_item.catalogue_variant.stock_qty.to_i - order_item.catalogue_variant.block_qty.to_i || 0)
            else
              result ||= order_item.quantity.to_i > (order_item.catalogue.stock_qty.to_i - order_item.catalogue.block_qty.to_i || 0)
            end
          end
        end
        result
      else
        OpenStruct.new(success?: false, msg: 'No item found in the cart', code: 400)
      end
    end
  end
end
