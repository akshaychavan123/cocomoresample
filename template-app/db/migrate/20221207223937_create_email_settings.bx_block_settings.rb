# This migration comes from bx_block_settings (originally 20210316102013)
class CreateEmailSettings < ActiveRecord::Migration[6.0]
  def change
    create_table :email_settings do |t|
      t.string :title
      t.text :content
      t.integer :event_name

      t.timestamps
    end
  end
end
