module BxBlockCart
  class CartsController < ApplicationController

    before_action :get_user, only: [:index, :create, :add_cart_item, :has_product, :reorder, :buy_now]
    before_action :status_in_cart?, only: [:add_cart_item]
    before_action :order_exists?, only: [:add_cart_item, :remove_cart_item,
                                         :check_availability_and_block, :release_products]
    before_action :fetch_modal_data, only: [:track]

    def index
      if params[:cart_id].present?
        orders = @current_user.orders.where(id: params[:cart_id])
      else
        orders = @current_user.orders.includes(
            order_items: [catalogue: %i[sub_categories brand]]
        ).order_in_cart
      end
      if orders.present?
        render json: CartSerializer.new(orders, serializable_options), status: 200
      else
        render json: {
            message: 'No order record found.',
            errors: [
                {message: 'No order record found.'}
            ]
        }, status: 200
      end
    end

    def create
      order = @current_user.orders.find_or_create_by(status: "in_cart")
      @res = AddProductInCart.new(params, order, @current_user).call
      update_cart_total(@res.data) if @res.success?
      if @res.success? && !@res.data.nil?
        order.reload
        order.update_column('total_tax', order.order_items.map(&:tax_charge).compact.sum.round(2))

        render json: CartSerializer.new(
          order, { params: { user: @current_user, order: true} }
        ), status: :ok
      else
        render json: { errors: [{ order: @res.msg }]}, status: :unprocessable_entity
      end
    end

    def add_cart_item
      @res = AddProductInCart.new(params, @order, @current_user).call
      update_cart_total(@res.data) if @res.success?
      if @res.success? && !@res.data.nil?
        order = BxBlockOrderManagement::Order.includes(
          order_items: [catalogue: %i[sub_categories brand]]
        ).find(@res.data.id)
        order.reload
        order.update_column('total_tax', order.order_items.map(&:tax_charge).compact.sum.round(2))
        render json: CartSerializer.new(
          order,
          { params: { user: @current_user, host: request.protocol + request.host_with_port } }
        ), status: 200
      else
        render json: { errors: [{ order: @res.msg }] }, status: :unprocessable_entity
      end
    end

    def remove_cart_item
      @response = RemoveProductFromCart.new(params, @order).call
      if @response.success? && !@response.data.nil?
        update_cart_total(@response.data)
        order = BxBlockOrderManagement::Order.includes(
          order_items: [catalogue: %i[sub_categories brand]]
        ).find(@response.data.id)
        render json: CartSerializer.new(
          order,
          { params: { user: @current_user, host: request.protocol + request.host_with_port } }
        ), status: 200
      else
        render json: { errors: [{ order: @response.msg }] }, status: :unprocessable_entity
      end
    end

    def empty_cart
      @order = BxBlockOrderManagement::Order.find(params[:cart_id])
      render(json: { message: "Cannot find order" }, status: 400) && return if @order.nil?

      @response = EmptyCart.new(params, @order).call
      if @response.success?
        @order.update(
            total: 0.0,
            sub_total: 0.0,
            total_tax: 0.0,
            coupon_code_id: nil,
            applied_discount: 0.0
        )
        render json: { message: @response.msg }, status: 200
      else
        render json: { errors: [{ order: @response.msg }] }, status: :unprocessable_entity
      end
    end

    def update_cart_item
      @response = UpdateCart.new(params).call
      if @response.success?
        update_cart_total(@response.data)
        order = BxBlockOrderManagement::Order.includes(
          order_items: [catalogue: %i[sub_categories brand]]
        ).find(@response.data.id)
        render json: CartSerializer.new(
          order,
          { params: { user: @current_user, host: request.protocol + request.host_with_port } }
        ), status: 200
      else
        render json: { errors: [{ order: @response.msg }], success: false }, status: :unprocessable_entity
      end
    end

    def buy_now
      order = @current_user.orders.new(status: "created")
      res = AddProductInCart.new(params, order, @current_user).call
      update_cart_total(res.data) if res.success?
      if res.success? && !res.data.nil?
        order = BxBlockOrderManagement::Order.includes(
          order_items: [catalogue: %i[sub_categories brand]]
        ).find(res.data.id)
        order.reload
        order.update_column('total_tax', order.order_items.map(&:tax_charge).compact.sum.round(2))
        render json: CartSerializer.new(
          order,
          { params: { user: @current_user, host: request.protocol + request.host_with_port } }
        ), status: 200
      else
        render json: { errors: [{ order: res.msg }] }, status: :unprocessable_entity
      end
    end

    def check_availability_and_block
      order_items = @order.order_items
      order_items.each do |order_item|
        @product_variant = order_item.catalogue_variant
        @product = order_item.catalogue
        if product_not_available?(order_item)
          if (@product_variant && @product_variant.available_stock_quantity < 1) || @product.available_stock_quantity < 1
            @error_message = "Sorry, #{@product.name} is out of stock. please update your cart."
          else
            @error_message = "Sorry, only #{@product_variant.present? ? @product_variant.available_stock_quantity : @product.available_stock_quantity } #{@product.name} in stock. please update your cart."
          end
          break
        end
      end
      Rails.logger.error ">>>>>>>>>>>>>>>>>Error Message: #{@error_message.present?}>>>>>>>>>>>>"

      if @error_message.present?
        render json: { errors: @error_message, product: @product_variant.present? ? @product_variant : @product }, status: :unprocessable_entity
      elsif true
        Rails.logger.error ">>>>>>>>>>>>>>>>>Inside check_availability_and_block Order: #{@order.id}>>>>>>>>>>>>"
        order_items.each do |order_item|
          product = order_item.catalogue_variant.present? ?
                        order_item.catalogue_variant : order_item.catalogue
          order_item_quantity = order_item.subscription_quantity.present? && order_item.subscription_quantity.to_i > 0 ? order_item.subscription_quantity.to_i : order_item.quantity.to_i
          block_qty = product.block_qty.to_i + order_item_quantity
          # block_qty = product.block_qty.to_i + order_item.quantity.to_i
          product.update_column('block_qty', block_qty)
          Rails.logger.error ">>>>>>>>>>>>>>>>>Product: #{product.inspect} #{order_item_quantity.to_i}>>>>>>>>>>>>"
          if product.class.name == "BxBlockCatalogue::CatalogueVariant"
            product.catalogue.update_column(
              'block_qty', product.catalogue.block_qty.to_i + order_item.quantity.to_i
            )
          end
        end

        if @order.update_columns(is_availability_checked: true, availability_checked_at: Time.now, is_blocked: true)
          Rails.logger.error ">>>>>>>>>>>>>>>>>Order is Updated>>>>>>>>>>>>"
        else
          Rails.logger.error ">>>>>>>>>>>>>>>>>Order: #{@order.errors.full_messages.to_sentence}>>>>>>>>>>>>"
        end
        # Rails.logger.error ">>>>>>>>>>>>>>>>>Order: #{@order.inspect}>>>>>>>>>>>>"
        render json: { data: {}, message: 'All products are available.' }, status: 200
      else
        Rails.logger.error ">>>>>>>>>>>>>>>>>Inside Else >>>>>>>>>>>>"
        render json: { data: {}, message: 'All products are available.' }, status: 200
      end
    end

    def release_products
      if @order.present?
        @order.update(is_blocked: nil, is_availability_checked: false)
        @order.order_items.each do |order_item|
          quantity = order_item.quantity.to_i
          subscription_quantity = order_item.subscription_quantity.to_i
          product = order_item.catalogue_variant.present? ? order_item.catalogue_variant : order_item.catalogue
          block_qty = product.block_qty.to_i - quantity - subscription_quantity
          product.update_column(:block_qty, block_qty)
          if product.class.name == "BxBlockCatalogue::CatalogueVariant"
            product.catalogue.update(block_qty: product.catalogue.block_qty.to_i - quantity)
          end
        end
        render json: { success: true, data: {} }, status: 200
      else
        render json: {
            message: 'order not found',
            errors: [
                {
                    message: "order not found"
                }
            ]
        }
      end
    end

    def has_product
      if @current_user.present?
        order = @current_user.orders.where(status: 'in_cart')&.last
        return render json: { success: false, message: 'order not found', errors: [{ message: "order not found" }] } if order.nil?

        order_items = order.order_items
        if order_items.present? && params[:catalogue_variant_id]
          order_items = order_items.where(catalogue_variant_id: params[:catalogue_variant_id])
        end
        render json: {
            data: {
              has_cart_product: order_items.present?, order_id: order.id,
              total_cart_item: BxBlockOrderManagement::Order.total_cart_item(@current_user),
              total_wishlist_items: @current_user.wishlist&.item_count || 0
            },
            success: true, message: ''
        }, status: 200
      else
        render json: {
          success: false, errors: [{ user: 'user not found' }]
        }, status: 400
      end
    end

    def reorder
      if @current_user.present?
        prev_order = @current_user.orders.find_by(id: params[:cart_id])
        render(json: { message: "Can't find order" }, status: 400) && return if prev_order.nil?
        current_order = @current_user.orders.in_cart.last
        if current_order.present?
          remaining_items = prev_order.order_items.where(
            catalogue_id: (
              prev_order.order_items.pluck(:catalogue_id) -
                current_order.order_items.pluck(:catalogue_id)
            )
          )
          remaining_items.each do |oi|
            current_order.order_items.create(quantity: oi.quantity, catalogue_id: oi.catalogue_id)
          end
        else
          current_order = @current_user.orders.create!
          prev_order.order_items.each do |oi|
            current_order.order_items.create(quantity: oi.quantity, catalogue_id: oi.catalogue_id)
          end
        end
        update_cart_total(current_order)
        render json: {
            data: {
                order_id: current_order.id
            },
            success: true,
            message: 'Order reordered successfully'
        },
               status: 200
      else
        render json: {
            success: false,
            errors: "user not found.",
            error_description: "The authorization server encountered an unexpected condition " \
                               "which prevented it from fulfilling the request."
        },
               status: 400
      end
    end

    def track
      # render(json: { message: "Order not found" }, status: 400) && return if @model_data.nil?
      data = @model_data&.trackings&.order(date: :desc)
      serializer = "BxBlockOrderManagement::#{params[:track].camelize}Serializer".constantize
      render json: {
          data: {
              tracking_detail: BxBlockOrderManagement::TrackingSerializer.new(
                data,
                {
                  params: {
                    current_user: @current_user,
                    current_account: @current_user,
                    show_history: true,
                    show_cart: true,
                    order: true,
                    order_date:true,
                    order_number:true
                  }
                }
              ),
              "#{params[:track]}_detail": serializer.new(@model_data)
          },
          success: true
      }, status: 200
    end

    private

    def update_cart_total(order)
      @cart_response = BxBlockOrderManagement::UpdateCartValue.new(order, @current_user).call
    end

    def serializable_options
      { params: { host: request.protocol + request.host_with_port } }
    end

    def order_exists?
      params[:cart_id] = params[:id]
      @order = BxBlockOrderManagement::Order.find(params[:cart_id])
    end

    def status_in_cart?
      params[:cart_id] = params[:id]
      order = @current_user.orders.find(params[:cart_id])
      unless order.status == 'in_cart'
        return render json: { errors: 'cart not present' }, status: :not_found
      end
    end

    def product_not_available?(order_item)
      (
        @product_variant.present? &&
            order_item.quantity.to_i > (
              @product_variant.stock_qty.to_i - @product_variant.block_qty.to_i
            )
      ) || order_item.quantity.to_i > (@product.stock_qty.to_i - @product.block_qty.to_i)
    end

    def fetch_modal_data
      model_name = "BxBlockOrderManagement::#{params[:track].camelize}".constantize
      @model_data = model_name.find_by(id: params[:id])
    end
  end
end

