# This migration comes from bx_block_notification_settings (originally 20200930095727)
class CreateNotificationGroups < ActiveRecord::Migration[6.0]
  def change
    create_table :notification_groups do |t|
      t.integer :group_type
      t.string :group_name
      t.references :notification_setting, null: false, foreign_key: true
      t.integer :state

      t.timestamps
    end
  end
end
