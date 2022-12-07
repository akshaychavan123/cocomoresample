# This migration comes from bx_block_file_upload (originally 20210312072818)
class CreateAttachments < ActiveRecord::Migration[6.0]
  def change
    create_table :attachments do |t|
      t.string :image
      t.string :image_file_name
      t.string :image_content_type
      t.integer :image_file_size
      t.string :attachable_type
      t.bigint :attachable_id
      t.integer :position
      t.boolean :is_default

      t.timestamps
    end
  end
end
