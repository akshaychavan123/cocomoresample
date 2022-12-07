module BxBlockFedexIntegration
  class ShipmentAttributesCreation

    attr_accessor :order, :user, :hyperpay, :shipping_address

    def initialize order, hyperpay
      @order = order
      @user = order.account
      @hyperpay = hyperpay
      delivery_addresses = order.delivery_address_orders
      @shipping_address = delivery_addresses.where(address_for: 'shipping').last&.delivery_address
      @shipping_address = delivery_addresses.where(address_for: 'billing_and_shipping').last&.delivery_address if @shipping_address.blank?
    end

    def call
      {
        "shipments_attributes": [{
          "full_truck": false,
          "load_description": "Dummy load description",
          "cod_value_attributes": {
            "amount": order.source == 'cod' ? order.total : nil,
            "currency": hyperpay.present? ? (hyperpay['currency'].present? ? hyperpay['currency'] : hyperpay['data']['currency']) : nil
          },
          "shipment_value_attributes": {
            "amount": order.source == 'online' ? order.total : nil,
            "currency": hyperpay.present? ? (hyperpay['currency'].present? ? hyperpay['currency'] : hyperpay['data']['currency']) : nil
          },
          "delivery_attributes": {
            "address": shipping_address.address,
            "city": shipping_address.city,
            "country": shipping_address.country,
            "email": user.email,
            "name": "#{user.first_name} #{user.last_name}",
            "phone": user.phone_number,
            "instructions": "delivery instructions",
            "arrival_window_attributes": {
                "begin_at": Time.current,
                "end_at": Time.current + 7.days
            },
            "coordinate_attributes": {
                "latitude": shipping_address.latitude,
                "longitude": shipping_address.longitude
            }
          },
          "pickup_attributes": {
            "address": "18, Vijay Nagar, Indore",
            "city": "Indore",
            "country": "India",
            "email": "pickup.demo@mailinator.com",
            "name": "Pickup user",
            "phone": "1234567891",
            "instructions": "pickup instructions",
            "arrival_window_attributes": {
                "begin_at": "2020-10-09 07:13:07 UTC",
                "end_at": "2020-10-15 07:13:07 UTC"
            },
            "coordinate_attributes": {
                "latitude": "22.759146",
                "longitude": "75.891044"
            }
          },
          "items_attributes": [
            {
              "weight": total_weight,
              "quantity": order_quantity,
              "stackable": true,
              "item_type": "PALLET",
              "dimension_attributes": {
                "height": 1,
                "length": 10,
                "width": 10

              }
            }
          ]
        }]
      }
    end

    def total_weight
      BxBlockCatalogue::Catalogue.active.joins(:order_items).where(id: order.order_items.pluck(:catalogue_id)).group("catalogues.id").sum(&:weight).to_f
    end

    def order_quantity
      order.order_items.group('order_items.id').sum(&:quantity).to_i
    end

  end
end
