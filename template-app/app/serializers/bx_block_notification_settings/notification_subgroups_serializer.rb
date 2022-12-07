module BxBlockNotificationSettings
  class NotificationSubgroupsSerializer < BuilderBase::BaseSerializer
    attributes :subgroup_type, :subgroup_name, :notification_group_id, :state
  end
end

