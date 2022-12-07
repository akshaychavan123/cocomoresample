module BxBlockCart
  class UpdateCart
    attr_accessor :params, :quantity, :product, :order, :order_item, :product_variant

    def initialize(params)
      @params       =   params
      @quantity     =   params[:subscription_quantity].present? ? params[:subscription_quantity] : params[:quantity]
      @order        =   BxBlockOrderManagement::Order.find(params[:cart_id])
      if params[:catalogue_variant_id].present?
        @order_item   =   @order.order_items.find_by(
          catalogue_id: params[:catalogue_id], catalogue_variant_id: params[:catalogue_variant_id]
        )
      else
        @order_items = @order.order_items.where(catalogue_id: params[:catalogue_id])

        @order_item = params[:subscription_quantity].present? ? @order_items.where.not(subscription_package: nil).last : @order_items.where(subscription_package: nil).last

      end
      @product      =   @order_item&.catalogue
      @product_variant = @order_item&.catalogue_variant
    end

    def call
      if product.present?
        if product_available?
          if params[:subscription_quantity].present?
            subscription_period = params[:subscription_period].present? ? params[:subscription_period] : order_item.subscription_period
            subscription_package = params[:subscription_package].present? ? params[:subscription_package] : order_item.subscription_package
            subscription_discount = params[:subscription_discount].present? ? params[:subscription_discount] : order_item.subscription_discount
            preferred_delivery_slot = params[:preferred_delivery_slot].present? ? params[:preferred_delivery_slot] : order_item.preferred_delivery_slot
            order_item.update(subscription_quantity: quantity, subscription_period: subscription_period, subscription_package: subscription_package, subscription_discount: subscription_discount, preferred_delivery_slot: preferred_delivery_slot)
          else
            order_item.update(quantity: quantity)
          end

          order_item.reload
          OpenStruct.new(success?: true, data: order, msg: 'Cart updated successfully', code: 200)
        else
          OpenStruct.new(
            success?: false, data: nil, msg: 'Sorry, Product is out of stock', code: 404
          )
        end
      else
        OpenStruct.new(
          success?: false,
          data: nil,
          msg: "Sorry, This product isn't available in your cart.",
          code: 404
        )
      end
    end

    private

    def product_available?
      if product_variant.present?
        quantity.to_i <= (product_variant&.stock_qty || 0)
      else
        quantity.to_i <= (product&.stock_qty || 0)
      end
    end

  end
end
