module BxBlockOrderManagement
  class TrackingSerializer < BuilderBase::BaseSerializer
    attributes :id, :status, :tracking_number, :date

    attribute :orders_details do |object,params|
      if params[:orders]
        params[:orders]
      end
    end

    attribute :order_date do |object|
      object.date&.in_time_zone(Order::TIME_ZONE).strftime("%a, #{object.date.in_time_zone(Order::TIME_ZONE).day.ordinalize} %B %Y")
    end

    attribute :order_datetime do |object|
      object.date&.in_time_zone(Order::TIME_ZONE).strftime("%a, #{object.date.in_time_zone(Order::TIME_ZONE).day.ordinalize} %B %Y - %I:%M %p")
    end

    attribute :order_items_details do |object,params|
      if params[:order_items]
        params[:order_items]
      end
    end

    attribute :message do |object|
      if object.status.to_s.titleize == 'New'
        "Your order is submitted to shipment partner."
      else
        "Your order has been #{object.status.to_s.titleize}"
      end
    end
  end
end
