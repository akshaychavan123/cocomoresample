require "uri"
require "net/http"

module BxBlockOrderManagement
  class ShipRocket
    attr_accessor :token
    shiprocket_configuration = BxBlockApiConfiguration::ApiConfiguration.find_by(configuration_type: 'shiprocket')
    SHIP_ROCKET_BASE_URL = "https://apiv2.shiprocket.in/v1/"
    SHIP_ROCKET_USER_EMAIL = shiprocket_configuration&.ship_rocket_user_email
    SHIP_ROCKET_USER_PASSWORD = shiprocket_configuration&.ship_rocket_user_password

    def authorize
      begin
        url = URI("#{SHIP_ROCKET_BASE_URL}"+"external/auth/login")

        https = Net::HTTP.new(url.host, url.port);
        https.use_ssl = true

        request = Net::HTTP::Post.new(url)
        request["Content-Type"] = "application/json"

        request.body = {
            "email"=> SHIP_ROCKET_USER_EMAIL,
            "password"=> SHIP_ROCKET_USER_PASSWORD
        }.to_json

        response = https.request(request)
        @token = JSON.parse(response.body)['token']

        # Get pickup location
        url = URI("#{SHIP_ROCKET_BASE_URL}"+"external/settings/company/pickup")
        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true
        request = Net::HTTP::Get.new(url)
        request["Content-Type"] = "application/json"
        request["Authorization"] = "Bearer #{@token}"
        pickup_location_response = https.request(request)
        @pickup_location = JSON.parse(pickup_location_response.body)['data']['shipping_address'][0]['pickup_location']
      rescue
        @token = nil
      end
    end

    def post_order(order_id)
      @order = BxBlockOrderManagement::Order.find_by(id: order_id)
      url = URI("#{SHIP_ROCKET_BASE_URL}"+"external/orders/create/adhoc")
      https = Net::HTTP.new(url.host, url.port);
      https.use_ssl = true
      request = Net::HTTP::Post.new(url)
      request["Content-Type"] = "application/json"
      request["Authorization"] = "Bearer #{@token}"
      request.body =  formated_body_data(@order)
      response = https.request(request)
    end

    def cancel_order(order_id)
      @order = BxBlockOrderManagement::Order.find_by(id: order_id)
      url = URI("#{SHIP_ROCKET_BASE_URL}"+"external/orders/cancel")
      https = Net::HTTP.new(url.host, url.port);
      https.use_ssl = true
      request = Net::HTTP::Post.new(url)
      request["Content-Type"] = "application/json"
      request["Authorization"] = "Bearer #{@token}"
      request.body = {
          "ids"=> [@order.ship_rocket_order_id]
      }.to_json
      response = https.request(request)
    end

    def get_order(order_id)
      @order = BxBlockOrderManagement::Order.find_by(id: order_id)
      url = URI("#{SHIP_ROCKET_BASE_URL}"+"external/orders/show/#{@order.ship_rocket_order_id}")
      https = Net::HTTP.new(url.host, url.port);
      https.use_ssl = true
      request = Net::HTTP::Get.new(url)
      request["Content-Type"] = "application/json"
      request["Authorization"] = "Bearer #{@token}"
      response = https.request(request)
      response
    end


    private

    def order_items(order)
      items = []
      order.order_items.each do |item|
        items << {"name"=> item.catalogue&.name, "sku"=>"#{item.order.id}-#{item.id}-#{item.catalogue.sku}", "units"=> item.quantity.present? ? item.quantity : item.subscription_quantity, "selling_price"=> item.unit_price}
      end
      items
    end

    def formated_body_data(order)
      @order = order
      delivery_addresses = @order.delivery_address_orders
      @delivery_address = delivery_addresses.where(address_for: 'shipping').last&.delivery_address
      @delivery_address = delivery_addresses.where(address_for: 'billing_and_shipping').last&.delivery_address if @delivery_address.blank?
      @shipping_address = delivery_addresses.where(address_for: 'billing').present? ? delivery_addresses.where(address_for: 'billing').last&.delivery_address : delivery_addresses.where(address_for: 'billing_and_shipping').last&.delivery_address

      {"order_id"=>@order.id.to_s,
       "order_date"=>@order.created_at.strftime('%Y-%m-%d %I:%M'),
       "pickup_location"=>@pickup_location,
       "channel_id"=>"Custom",
       "billing_customer_name"=>@order.account&.full_name.split.first.to_s,
       "billing_last_name"=>@order.account&.full_name.split.last.to_s,
       "billing_address"=>"#{@delivery_address&.flat_no}, #{@delivery_address&.address}" ,
       "billing_address_2"=>@delivery_address&.address_line_2,
       "billing_city"=>@delivery_address&.city,
       "billing_pincode"=> @delivery_address&.zip_code ,
       "billing_state"=>@delivery_address&.state,
       "billing_country"=>@delivery_address&.country,
       "billing_email"=>@order.account.email,
       "billing_phone"=>@delivery_address&.phone_number,
       "shipping_is_billing"=> shipping_and_billing_same?(@delivery_address),
       "shipping_customer_name"=> @order.account&.full_name.split.first.to_s,
       "shipping_last_name"=>@order.account&.full_name.split.last.to_s,
       "shipping_address"=>"#{@shipping_address&.flat_no}, #{@shipping_address&.address}",
       "shipping_address_2"=>@shipping_address&.address_line_2,
       "shipping_city"=>@shipping_address&.city,
       "shipping_pincode"=>@shipping_address&.zip_code,
       "shipping_country"=>@shipping_address&.country,
       "shipping_state"=>@shipping_address&.state,
       "shipping_email"=>@order.account.email,
       "shipping_phone"=>@shipping_address&.phone_number,
       "order_items"=> order_items(@order),
       "payment_method"=>@order.source,
       "shipping_charges"=>@order.shipping_total,
       "total_discount"=>@order.applied_discount,
       "sub_total"=>@order.sub_total,
       "length"=>@order.length,
       "breadth"=>@order.breadth,
       "height"=>@order.height,
       "weight"=>@order.weight
      }.to_json
    end

    def shipping_and_billing_same?(address)
      address&.address_for.to_s.include?('billing_and_shipping')
    end

  end
end
