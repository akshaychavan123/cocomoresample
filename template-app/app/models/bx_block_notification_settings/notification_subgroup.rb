# == Schema Information
#
# Table name: notification_subgroups
#
#  id                    :bigint           not null, primary key
#  subgroup_type         :integer
#  subgroup_name         :string
#  notification_group_id :bigint           not null
#  state                 :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
module BxBlockNotificationSettings
  class NotificationSubgroup < BxBlockNotificationSettings::ApplicationRecord
    include NotificationSettingsStates

    belongs_to :notification_group,
               class_name: 'BxBlockNotificationSettings::NotificationGroup',
               foreign_key: 'notification_group_id'

    self.table_name = :notification_subgroups

    SUBGROUPS_TYPE = {
      wishlist_item_out_of_stock: 0,
      out_of_stock_notification: 1,
      new_order: 2,
      order_cancelled: 3,
      on_hold: 4,
      order_shipped: 5,
      order_delivered: 6,
      refunded: 7
    }.freeze

    enum state: STATES
    enum subgroup_type: SUBGROUPS_TYPE
  end
end
