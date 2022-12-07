module BxBlockNotificationSettings
  class NotificationGroupsSerializer < BuilderBase::BaseSerializer
    attributes :group_type, :group_name, :notification_setting_id, :state

    attribute :notification_subgroups do |object|
      NotificationSubgroupsSerializer.new(object.notification_subgroups).serializable_hash
    end
  end
end

