module BxBlockNotification
  class Notification < BxBlockNotification::ApplicationRecord
    self.table_name = :notifications

    after_create :send_notification

    belongs_to :account, class_name: "AccountBlock::Account"

    NOTIFICATION_KEYS = {
      PLACED: 'Order placed',
      CANCELLED: 'Order cancelled',
      CONFIRMED: 'Order confirmed',
      DELIVERED: 'Order delivered',
      IN_TRANSIT: 'Order in transit'
    }

    def send_notification
      BxBlockNotification::SendNotification.new(self).call
    end
  end
end
