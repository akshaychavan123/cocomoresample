module BxBlockOrderManagement
  class SubscriptionOrder < BxBlockOrderManagement::ApplicationRecord
    self.table_name = :subscription_orders
    include AASM

    PAGE = 1
    PER_PAGE = 10

    default_scope { order(delivery_date: :asc) }

    belongs_to :order_item, class_name: "BxBlockOrderManagement::OrderItem"

    after_commit :extend_delivery_date, if: :delivery_cancelled?

    aasm column: 'status' do
      state :pending, initial: true
      state :delivered, :cancelled

      event :deliver_order do
        transitions from: :pending, to: :delivered
      end

      event :cancel_order do
        transitions from: :pending, to: :cancelled
      end
    end

    def extend_delivery_date
      order_item = self.order_item
      subscription_order = order_item.subscription_orders.last
      if order_item.subscription_package.to_s.downcase == 'daily'
        delivery_date = subscription_order.delivery_date + 1.days
      elsif order_item.subscription_package.to_s.downcase == 'weekly'
        delivery_date = subscription_order.delivery_date + 1.weeks
      elsif order_item.subscription_package.to_s.downcase == 'monthly'
        delivery_date = subscription_order.delivery_date + 1.months
      end
      order_item.subscription_orders.create(delivery_date: delivery_date, quantity: order_item.subscription_quantity)
    end

    def delivery_cancelled?
      self.cancelled?
    end
  end
end
