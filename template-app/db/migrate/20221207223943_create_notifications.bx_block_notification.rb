# This migration comes from bx_block_notification (originally 20210407153406)
class CreateNotifications < ActiveRecord::Migration[6.0]
  def change
    create_table :notifications do |t|
      t.string :source
      t.integer :source_id
      t.string :message
      t.string :title
      t.references :account, foreign_key: true
      t.boolean :is_read, :null => false, :default => false

      t.timestamps
    end
  end
end
