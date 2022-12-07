# This migration comes from bx_block_file_upload (originally 20210323042235)
class AddColumnsToAttachment < ActiveRecord::Migration[6.0]
  def change
    add_column :attachments, :url_type, :string
    add_column :attachments, :url_id, :integer
    add_column :attachments, :url, :string
    add_column :attachments, :category_url_id, :integer
    add_column :attachments, :title, :string
    add_column :attachments, :subtitle, :text
  end
end
