module BxBlockOrderManagement
  class OrderTransactionsController < ApplicationController
    before_action :is_guest, only: [:create, :show]
    before_action :find_order, only: [:show]

    def create
      @response = CreateOrder.new(params).call
      if @response.success?
        session.delete("order_#{@response.order.id}_warning")
        render json: {
          message: @response.msg,
          data: @response.order
        }, status: 200
      else
        render json: { errors: [@response.msg] }, status: :unprocessable_entity
      end
    end

    def show
      render(json: { message: "Order not found" }, status: 400) && return if @order.nil?

      order_transactions = @order&.order_transactions
      if order_transactions
        render json: {
          data:
          {
            order_transaction: OrderTransactionSerializer.new(order_transactions)
          }
        }, status: 200
      end
    end

    def is_guest
      if @current_user.guest?
        return render json: {message: "Please login or signup to access services"}, status: :unprocessable_entity
      end
    end

    private

    def find_order
      @order = BxBlockOrderManagement::Order.find(params[:cart_id])
    end
  end
end
