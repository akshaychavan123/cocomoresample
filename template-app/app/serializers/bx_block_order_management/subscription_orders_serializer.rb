module BxBlockOrderManagement
  class SubscriptionOrdersSerializer < BuilderBase::BaseSerializer
    attributes :id, :delivery_date, :quantity, :status, :order_item_id

    attribute :delivery_date do |object|
      object.delivery_date&.in_time_zone(Order::TIME_ZONE)&.strftime("%a, #{object.delivery_date&.in_time_zone(Order::TIME_ZONE)&.day.ordinalize} %B %Y")
    end
  end
end
