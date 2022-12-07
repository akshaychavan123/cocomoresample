module BxBlockNotification
  class PushNotificationJob < ApplicationJob
    queue_as :default
    def perform(resource)
      AccountBlock::Account.where(is_notification_enabled: true).each do |user|
        message = "#{resource&.message}"
        title = "#{resource&.title}"

        user&.notifications.create(source: resource.class.name, title: title, source_id: resource.id, message: message)
        BxBlockNotification::SendNotification.new("", message, title, user, "").call if user.present?
      end
    end
  end
end
