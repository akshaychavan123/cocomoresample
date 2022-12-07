# This migration comes from bx_block_settings (originally 20210316103346)
class AddSlugToEmailSettings < ActiveRecord::Migration[6.0]
  def change
    add_column :email_settings, :slug, :string
    add_index :email_settings, :slug, unique: true
  end
end
