module BxBlockOrderManagement
  class ShipmentsController < ApplicationController
    skip_before_action :validate_json_web_token, :only => [:status_update]
    skip_before_action :get_user, :only => [:status_update]
    before_action :find_shipment, except: [:status_update]

    def shipment_info
      if params[:order_item_id].present? && params[:track].present?
        model_name = "BxBlockOrderManagement::#{params[:track].camelize}".constantize
        @model_data = model_name.find_by(id: params[:order_item_id])

        data = @model_data&.trackings&.order(date: :desc)
        serializer = "BxBlockOrderManagement::#{params[:track].camelize}Serializer".constantize

        render json: {
          data: {
            tracking_detail: BxBlockOrderManagement::TrackingSerializer.new(data,  { params: { current_user: @current_user, current_account: @current_user, show_history: true, show_cart: true, order: true, order_date:true, order_number:true} } ),
            "#{params[:track]}_detail": serializer.new(@model_data)
          },
          success: true
        },
               status: 200
      elsif @order.present?
        render json: {"success": true,"message": "", data:{ tracking: tracking}}, status: :ok
      else
        json_response({
            success: false,
            errors: "Shipment Not Found.",
            error_description: "This order don't have any shipment."
          }, 404)
      end
    end

    def tracking
      @delivery_address = @order.delivery_addresses.where(is_default: true).first
      ship_rocket = BxBlockOrderManagement::ShipRocket.new
      ship_rocket.authorize
      response = ship_rocket.get_order(@order.id)
      ship_rocket_status = JSON.parse(response.body)['data']['status'].to_s.downcase
      if ship_rocket_status == 'canceled'
        status = 'cancelled'
      else
        status = ship_rocket_status.to_s.downcase
      end
      { order_number: @order.order_number,
        name: @delivery_address&.name,
        phone_number: @delivery_address&.phone_number,
        address: @delivery_address&.full_address,
        order_date: @order.order_date.strftime("%a, #{@order.order_date.day.ordinalize} %B %Y"),
        order_datetime: date_convertor(@order.order_date),
        tracking_number: @order.ship_rocket_shipment_id,
        status: status,
        msg: message_convert(status) }
    end

    def status_update
      @order = BxBlockOrderManagement::Order.find_by(ship_rocket_order_id: params[:order_id])
      if @order.present?
        @order.update(ship_rocket_status: params[:current_status].to_s.downcase)
        if @order.order_items.present?
          @order.order_items.each do |order_item|
            tracking = BxBlockOrderManagement::Tracking.find_or_create_by(date: DateTime.current, status: params[:current_status].to_s.downcase)
            order_item.order_trackings.create(tracking_id: tracking.id)
          end
        end
      end
      render plain: "OK"
    end

    private

    def message_convert(status)
      @status = status.to_s.downcase
      if @status == 'new'
        "Your order is submitted to shipment partner."
      else
        "Your order has been #{@status}"
      end
    end

    def date_convertor(d)
      date = d.to_datetime
      date&.strftime("%a, #{date.day.ordinalize} %B %Y , %I:%M%p")
    end

    def find_shipment
      @order = Order.find_by_id(params[:order_id])
      render_not_found 'order not found' unless @order
    end
  end
end
