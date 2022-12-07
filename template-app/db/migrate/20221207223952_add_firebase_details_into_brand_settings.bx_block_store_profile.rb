# This migration comes from bx_block_store_profile (originally 20210330124625)
class AddFirebaseDetailsIntoBrandSettings < ActiveRecord::Migration[6.0]
  def change
    add_column :brand_settings, :api_key, :string
    add_column :brand_settings, :auth_domain, :string
    add_column :brand_settings, :database_url, :string
    add_column :brand_settings, :project_id, :string
    add_column :brand_settings, :storage_bucket, :string
    add_column :brand_settings, :messaging_sender_id, :string
    add_column :brand_settings, :app_id, :string
    add_column :brand_settings, :measurement_id, :string
  end
end
