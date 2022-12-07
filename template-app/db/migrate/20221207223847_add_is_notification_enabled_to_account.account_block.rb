# This migration comes from account_block (originally 20210311113541)
class AddIsNotificationEnabledToAccount < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :is_notification_enabled, :boolean, default: true
  end
end
