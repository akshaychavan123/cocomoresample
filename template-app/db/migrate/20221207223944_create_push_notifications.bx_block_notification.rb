# This migration comes from bx_block_notification (originally 20210915080340)
class CreatePushNotifications < ActiveRecord::Migration[6.0]
  def change
    create_table :push_notifications do |t|
      t.string :message

      t.timestamps
    end
  end
end
