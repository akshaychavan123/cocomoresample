module BxBlockCart
  class RemoveProductFromCart
    attr_accessor :params, :order_item, :order

    def initialize(params, order)
      @order = order
      if params[:catalogue_variant_id].present?
        @order_item = @order.order_items.find_by(
          catalogue_id: params[:catalogue_id], catalogue_variant_id: params[:catalogue_variant_id]
        )
      else
        @order_items = @order.order_items.where(catalogue_id: params[:catalogue_id])
        @order_item = params[:subscription_quantity].present? ? @order_items.where.not(subscription_package: nil).last : @order_items.where(subscription_package: nil).last
      end
    end

    def call
      if order_item.blank?
        OpenStruct.new(
          success?: false, data: nil, msg: 'Sorry, Order item is not found.', code: 404
        )
      else
        order_item.destroy! if order_item.present?
        OpenStruct.new(
          success?: true, data: order, msg: 'Item removed from cart successfully', code: 200
        )
      end
    end

  end
end
