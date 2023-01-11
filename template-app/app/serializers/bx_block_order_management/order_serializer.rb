# == Schema Information
#
# Table name: orders
#
#  id                      :bigint           not null, primary key
#  order_number            :string
#  amount                  :float
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  account_id              :bigint
#  coupon_code_id          :bigint
#  delivery_address_id     :bigint
#  sub_total               :decimal(, )      default(0.0)
#  total                   :decimal(, )      default(0.0)
#  status                  :string
#  applied_discount        :decimal(, )      default(0.0)
#  cancellation_reason     :text
#  order_date              :datetime
#  is_gift                 :boolean          default(FALSE)
#  placed_at               :datetime
#  confirmed_at            :datetime
#  in_transit_at           :datetime
#  delivered_at            :datetime
#  cancelled_at            :datetime
#  refunded_at             :datetime
#  source                  :string
#  shipment_id             :string
#  delivery_charges        :string
#  tracking_url            :string
#  schedule_time           :datetime
#  payment_failed_at       :datetime
#  returned_at             :datetime
#  tax_charges             :decimal(, )      default(0.0)
#  deliver_by              :integer
#  tracking_number         :string
#  is_error                :boolean          default(FALSE)
#  delivery_error_message  :string
#  payment_pending_at      :datetime
#  order_status_id         :integer
#  is_group                :boolean          default(TRUE)
#  is_availability_checked :boolean          default(FALSE)
#  shipping_charge         :decimal(, )
#  shipping_discount       :decimal(, )
#  shipping_net_amt        :decimal(, )
#  shipping_total          :decimal(, )
#  total_tax               :float
#
module BxBlockOrderManagement
  class OrderSerializer < BuilderBase::BaseSerializer

    # belongs_to :account, serializer: AccountBlock::AccountSerializer, if: Proc.new {|rec, params| params[:user].present? }
    # has_many :order_items, serializer: BxBlockOrderManagement::OrderItemSerializer
    # has_many :delivery_addresses, serializer: AddressesSerializer

    attributes *[
      :id,
      :order_number,
      :amount,
      :account_id,
      :coupon_code_id,
      :delivery_address_id,
      :sub_total
    ]

    attribute :items_total do |object|
      object.items_total
    end

    attribute :total do |object|
      object.total.round(2)
    end

    attributes *[
      :status,
      :applied_discount,
      :cancellation_reason,
      :order_date,
      :is_gift,
      :placed_at,
      :confirmed_at,
      :in_transit_at,
      :delivered_at,
      :cancelled_at,
      :refunded_at,
      :source,
      :shipment_id,
      :delivery_charges,
      :tracking_url,
      :schedule_time,
      :payment_failed_at,
      :payment_pending_at,
      :returned_at,
      :tax_charges,
      :deliver_by,
      :tracking_number,
      :is_error,
      :delivery_error_message,
      :order_status_id,
      :is_group,
      :is_availability_checked,
      :shipping_charge,
      :shipping_discount,
      :shipping_net_amt,
      :shipping_total,
      :total_tax,
      :created_at,
      :updated_at,
      :delivery_addresses,
      :razorpay_order_id,
      :logistics_ship_rocket_enabled
    ]

    attribute :order_items do |object, params|
      if object.present?
        OrderItemSerializer.new(object.order_items, { params: params } ).serializable_hash[:data]
      end
    end

    attribute :account do |object|
      if object.present?
        AccountBlock::AccountSerializer.new(object.account).serializable_hash[:data]
      end
    end

    attribute :order_transaction do |object|
      if object.present?
        object.order_transactions
      end
    end

    attribute :coupon do |object|
      if object.present?
        BxBlockCouponCodeGenerator::CouponCodeSerializer.new(object.coupon_code).serializable_hash[:data]
      end
    end

    attribute :delivered_on do |object|
      object.delivered_at&.utc&.strftime("%a, #{object.delivered_at&.utc&.day&.ordinalize} %B '%y")
    end

    attribute :delivery_address do |object|
      if object.delivery_address_orders.present?
        delivery_address_order = object.delivery_address_orders.where(order_id: object.id, delivery_address_id: object.delivery_address_id).last
        delivery_address_order&.delivery_address if delivery_address_order.present?
      end
    end

    attribute :order_cancelled do |object|
      object.cancelled?
    end

    attribute :order_date do |object|
      object.order_date&.in_time_zone(Order::TIME_ZONE)&.strftime("%a, #{object.order_date&.utc&.day.ordinalize} %B %Y")
    end

    attribute :is_review_present do |object|
      object.review.present? ? true : false
    end

    attribute :review do |object|
      review = object.review
      {id:review&.id, comment:review&.comment, rating:review&.rating } if review.present?
    end

    attribute :shipping_charges do |object|
      object.shipping_charge_details
    end

    attribute :ship_rocket_status do |object|
      if object.logistics_ship_rocket_enabled
        ship_rocket = BxBlockOrderManagement::ShipRocket.new
        ship_rocket.authorize
        response = ship_rocket.get_order(object.id)
        status = JSON.parse(response.body)['data']['status'].to_s.downcase rescue ''
        if status == 'canceled'
          'cancelled'
        else
          status
        end
      end
    end
  end
end
