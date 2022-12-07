# This migration comes from bx_block_store_profile (originally 20210407100614)
class AddAddressToBrandSettings < ActiveRecord::Migration[6.0]
  def change
    add_column :brand_settings, :address, :string
    add_column :brand_settings, :gst_number, :string
  end
end
