module BxBlockNotification
  class PushNotification < BxBlockNotification::ApplicationRecord
    self.table_name = :push_notifications

    # after_create :send_push_notification

    # def send_push_notification
    #   BxBlockNotification::SendPushNotification.new(self).call
    # end
  end
end
