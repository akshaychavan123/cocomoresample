module BxBlockCart
  class EmptyCart
    attr_accessor :order_items, :order, :params

    def initialize(params, order)
      @order = order
      @order_items = @order.order_items
    end

    def call
      if order_items.count == 0
        OpenStruct.new(success?: false, msg: 'No order item found.', code: 404)
      else
        order_items.destroy_all
        OpenStruct.new(success?: true, msg: 'Items removed from cart successfully', code: 200)
      end
    end
  end
end
