# == Schema Information
#
# Table name: notification_groups
#
#  id                      :bigint           not null, primary key
#  group_type              :integer
#  group_name              :string
#  notification_setting_id :bigint           not null
#  state                   :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
module BxBlockNotificationSettings
  class NotificationGroup < BxBlockNotificationSettings::ApplicationRecord
    include NotificationSettingsStates

    belongs_to :notification_settings, class_name: 'BxBlockNotificationSettings::NotificationSetting',
               foreign_key: 'notification_setting_id'

    has_many :notification_subgroups,
             class_name: 'BxBlockNotificationSettings::NotificationSubgroup',
             foreign_key: 'notification_group_id',
             dependent: :destroy

    self.table_name = :notification_groups

    GROUPS_TYPE = {
      account_group: 0,
      item_group: 1,
      order_group: 2
    }.freeze

    enum state: STATES
    enum group_type: GROUPS_TYPE

    def set_inactive
      self.state = STATES[:inactive]
      save

      notification_subgroups.update_all(state: STATES[:inactive])
    end
  end
end
