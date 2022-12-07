module BxBlockShippingCharge
  class ShippingChargeController < BxBlockShippingCharge::ApplicationController
    def calculate_shipping_charge
      response = BxBlockShippingCharge::UpdateShippingChargeValue.new(params).call
      if response.success?
        order = response.data[:order]
        render json: BxBlockCart::CartSerializer.new(order, serializable_options), status: 200
      else
        render json: { message: response.message, errors: { message: response.message } }, status: response.status
      end
    end

    def release_shipping_charge
      @order  = BxBlockOrderManagement::Order.find_by(id: params[:cart_id])
      if @order.present?
        BxBlockOrderManagement::UpdateCartValue.new(@order, @current_user, true).call
        render json: { success: true, data: {} }, status: 200
      else
        render json: { message: 'Order not found', errors: { message: 'Order not found' } }, status: 400
      end
    end

    private

    def serializable_options
      { params: { host: request.protocol + request.host_with_port } }
    end
  end
end
