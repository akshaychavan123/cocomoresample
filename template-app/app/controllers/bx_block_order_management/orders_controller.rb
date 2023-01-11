module BxBlockOrderManagement
  class OrdersController < ApplicationController
    MONTHLY_ORDERS_TOKEN = "bTEQzks87PCxLT4OLf1iAg"
    before_action :check_order_item, only: [:show]
    before_action :check_order, only: [:update_payment_source]
    before_action :check_order_in_cart, only: [:apply_coupon, :remove_coupon]
    before_action :is_guest, only: [:my_orders, :create, :show, :cancel_order, :add_address_to_order, :update_payment_source]

    def my_orders
      orders = @current_user.orders.includes(:coupon_code, order_items: [catalogue: %i[sub_categories brand]]).where.not(status: ['in_cart','created']).order(placed_at: :desc)
      if orders.present? && params[:per_page].present?
        mod = orders.count % params[:per_page].to_i
        pages = orders.count / params[:per_page].to_i
        pages += 1 if mod > 0
      else
        pages = 0
      end
      count = orders.length
      page_no = params[:page].to_i == 0 ? 1 : params[:page].to_i
      per_page = params[:per_page].to_i == 0 ? 10 : params[:per_page].to_i
      orders = orders.page(page_no).per(per_page)
      render json: {
        data: {
          order: OrderSerializer.new(orders, { params: { host: request.protocol + request.host_with_port, current_user: @current_user, current_account: @current_account , order: true }}),
          meta: {
            pagination: {
              current_page: orders.current_page,
              next_page: orders.next_page,
              prev_page: orders.prev_page,
              total_pages: pages.present? ? pages : '',
              total_count: count
            }
          },
          status: 200
        }
      }
    end

    def create
      @res = AddProduct.new(params, @current_user).call
      update_cart_total(@res.data) if @res.success?
      if @res.success? && !@res.data.nil?
        order = Order.includes(:coupon_code, order_items: [catalogue: %i[sub_categories brand]]).find(@res.data.id)
        render json: {
          data:
            {
              coupon_message: @cart_response.nil? || @cart_response.success? ? nil : @cart_response.msg,
              order: OrderSerializer.new(order, { params: { user: @current_user, host: request.protocol + request.host_with_port } })
            }
        }, status: "200"
      else
        render json: { errors: @res.msg }, status: @res.code
      end
    end

    def show
      if @order_item.order.account_id == @current_user.id
        render json: OrderItemSerializer.new(@order_item, { params: { order: true, host: request.protocol + request.host_with_port } } ).serializable_hash,
               status: :ok
      else
        render json: "Order item not belongs to you", status: :unprocessable_entity
      end
    end


    def cancel_order
      order = @current_user.orders.find_by!(id: params[:order_id])
      order_status_id = BxBlockOrderManagement::OrderStatus.find_or_create_by(status: 'cancelled', event_name: 'cancel_order').id
      unless order.in_cart?
        if params[:item_id].present?
          order.order_items.where(id:params[:item_id]).map{ |a| a.update(order_status_id: order_status_id, cancelled_at: Time.current) }
          order.update(order_status_id: order_status_id, status: 'cancelled', cancelled_at: Time.current) if order.full_order_cancelled?
        else
          order.update!(order_status_id: order_status_id, status: "cancelled", cancellation_reason: params[:cancellation_reason])
        end
        render json: { data: { message: 'Order cancelled successfully' } },
               status: :ok
      else
        render json: {
          errors: [{
                     order: 'Your order is in cart. so no need to cancel it',
                   }],
        }, status: :unprocessable_entity
      end
    end

    def add_address_to_order
      address = params[:address][:country].downcase
      billing_address = params[:address][:billing_address][:country].downcase
      if !((address == "india" or address == "uk") and (billing_address == "india" or billing_address == "uk"))
        render json: {
          success: false,
          errors: "Country is not valid",
        }, status: 400
      else
        x = AddAddressToOrder.new(params, @current_user).call
        if x.success?
          render json: { message: x.msg }, status: x.code
        else
          render json: { message: x.msg }, status: x.code
        end
      end
    end

    def update_payment_source
      x = UpdatePayment.new(params, @order).call
      if x.present?
        if x.success?
          render json: { message: x.msg }, status: x.code
        else
          render json: { message: x.msg }, status: x.code
        end
      else
        render json: { message: 'Payment source is not updated' }, status: 400
      end
    end

    def apply_coupon
      @coupon =  BxBlockCouponCodeGenerator::CouponCode.find_by(code: params[:code])
      render(json: { message: "Invalid coupon" }, status: 400) && return if @coupon.nil?
      render(json: { message: "Can't find order" }, status: 400) && return if @order.nil?
      @response = ApplyCoupon.new(@order, @coupon, params).call
      if @response.success?
        render json: {
          data:
            {
              message: @response.msg,
              coupon: OrderSerializer.new(@order)
            }
        }, status: 200
      else
        render json: { errors: [@response.msg] }, status: :unprocessable_entity
      end
    end

    def remove_coupon
      render(json: { message: "Can't find order" }, status: 400) && return if @order.nil?

      applied_discount = @order.applied_discount
      if @order.update!(coupon_code_id: nil, applied_discount: 0, total: (@order.total + applied_discount), sub_total: (@order.sub_total + applied_discount))
        #update_cart_total(@order)
        @order.order_items.each do |order_item|
          if order_item.catalogue_variant_id.present?
            price = order_item.catalogue_variant.sale_price.present? ? order_item.catalogue_variant.sale_price : order_item.catalogue_variant.price
            tax_amount = order_item.catalogue_variant.tax_amount
          else
            price = order_item.catalogue.sale_price.present? ? order_item.catalogue.sale_price : order_item.catalogue.price
            tax_amount = order_item.catalogue.tax_amount
          end
          order_item.update_columns(unit_price: price, total_price: (price * order_item.order_item_qty), tax_amount: tax_amount)
        end
        @order.update_column('total_tax', @order.order_items.map(&:tax_charge).compact.sum.round(2))
        render json: {
          data:
            {
              coupon: OrderSerializer.new(@order)
            }
        }, status: 200
      else
        render json: {
          success: false,
          errors: "Something went wrong!",
          error_description: "The authorization server encountered an unexpected condition which prevented it from fulfilling the request."
        }, status: 400
      end
    end

    def get_monthly_orders
      return render json: {errors: [{message: "Invalid Token"},]}, status: :unprocessable_entity unless request.headers[:token].to_s == MONTHLY_ORDERS_TOKEN
      orders = BxBlockOrderManagement::Order.where(placed_at: (Date.today.at_beginning_of_month..Date.tomorrow))
      render json: {
        message: "",
        orders: BxBlockOrderManagement::OrderDetailSerializer.new(orders).serializable_hash, orders_count: orders.count, status: :ok}
    end

    # def export_csv
    #   collection = params[:order_ids]
    #   csv = CsvGenerate.new(collection).call
    #   send_data(csv, :type => 'test/csv', :filename => 'report.csv')
    # end

    private

    def is_guest
      if @current_user.guest?
        return render json: {message: "Please login or signup to access services"}, status: :unprocessable_entity
      end
    end

    def check_order_item
      @order_item = OrderItem.find(params[:id])
    end

    def check_order
      @order = @current_user.orders.find(params[:order_id])
    end

    def update_cart_total(order)
      @cart_response = UpdateCartValue.new(order, @current_user).call
    end

    def check_order_in_cart
      @order = @current_user.orders.where(status: ['in_cart', 'created']).find(params[:cart_id])
    end

    def serializable_options
      { params: { host: request.protocol + request.host_with_port } }
    end
  end
end
