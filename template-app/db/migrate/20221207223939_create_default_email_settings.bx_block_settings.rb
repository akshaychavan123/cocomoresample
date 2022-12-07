# This migration comes from bx_block_settings (originally 20210316142029)
class CreateDefaultEmailSettings < ActiveRecord::Migration[6.0]
  def change
    create_table :default_email_settings do |t|
      t.string :brand_name
      t.string :from_email
      t.string :recipient_email
      t.string :logo_file_name
      t.string :logo_content_type
      t.integer :logo_file_size
      t.datetime :logo_updated_at
      t.string :contact_us_email_copy_to
      t.string :send_email_copy_method

      t.timestamps
    end
  end
end
