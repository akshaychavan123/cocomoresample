# This migration comes from bx_block_notification (originally 20210915100153)
class AddColTitlePushNotification < ActiveRecord::Migration[6.0]
  def change
    add_column :push_notifications, :title, :string
  end
end
