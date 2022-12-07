# == Schema Information
#
# Table name: notification_settings
#
#  id          :bigint           not null, primary key
#  title       :string
#  description :string
#  state       :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
module BxBlockNotificationSettings
  class NotificationSetting < BxBlockNotificationSettings::ApplicationRecord
    include NotificationSettingsStates

    has_many :notification_groups, class_name: 'BxBlockNotificationSettings::NotificationGroup',
                                   foreign_key: 'notification_setting_id',
                                   dependent: :destroy

    enum state: STATES

    self.table_name = :notification_settings
  end
end
