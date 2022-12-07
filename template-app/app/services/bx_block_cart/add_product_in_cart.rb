module BxBlockCart
  class AddProductInCart
    attr_accessor :params, :quantity, :catalogue, :order, :user, :catalogue_variant

    def initialize(params, order, user)
      @params = params
      @quantity = @params[:subscription_quantity].present? ? @params[:subscription_quantity] : @params[:quantity]
      @catalogue_id = @params[:catalogue_id]
      @catalogue = BxBlockCatalogue::Catalogue.active.find(@catalogue_id)
      @catalogue_variant = @catalogue.catalogue_variants.find_by(id: @params[:catalogue_variant_id])
      @order = order
      @user = user
    end

    def call
      if order.blank?
        return OpenStruct.new(
          success?: false, data: nil, msg: 'Sorry, cart is not found', code: 404
        )
      elsif params[:catalogue_variant_id].present? && catalogue_variant.blank?
        return OpenStruct.new(
          success?: false, data: nil,
          msg: 'Sorry, Product Variant is not found for this product', code: 404
        )
      elsif product_not_available?
        if catalogue_variant.present?
          max_quantity = @catalogue_variant.stock_qty.to_i - @catalogue_variant.block_qty.to_i
        else
          max_quantity = @catalogue.stock_qty.to_i - @catalogue.block_qty.to_i
        end
        return OpenStruct.new(
          success?: false, data: nil, msg: "Sorry, you cannot add more than #{max_quantity} quantity", code: 404
        )
      else
        oi = order.order_items.build(order_item_params)
        if oi.save
          msg = "Item added in cart successfully"
          return OpenStruct.new(success?: true, data: order, msg: msg, code: 200)
        else
          return OpenStruct.new(success?: false, data: nil, msg: oi.errors.full_messages, code: 422)
        end
      end
    end

    private

    def product_not_available?
      if catalogue_variant.present?
        quantity.to_i > (@catalogue_variant.stock_qty.to_i - @catalogue_variant.block_qty.to_i || 0)
      else
        quantity.to_i > (@catalogue.stock_qty.to_i - @catalogue.block_qty.to_i || 0)
      end
    end

    def order_item_params
      params.permit(:quantity, :subscription_quantity, :catalogue_id, :catalogue_variant_id, :subscription_period, :subscription_package, :preferred_delivery_slot, :subscription_discount)
    end
  end
end
