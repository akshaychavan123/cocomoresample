module BxBlockNotificationSettings
  class NotificationSettingsSerializer < BuilderBase::BaseSerializer
    attributes :title, :description, :state, :notification_groups

    attribute :notification_groups do |object|
      NotificationGroupsSerializer.new(object.notification_groups).serializable_hash
    end
  end
end

