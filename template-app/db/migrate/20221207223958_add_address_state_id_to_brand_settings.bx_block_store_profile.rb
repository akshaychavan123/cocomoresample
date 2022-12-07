# This migration comes from bx_block_store_profile (originally 20220513110556)
class AddAddressStateIdToBrandSettings < ActiveRecord::Migration[6.0]
  def change
    add_column :brand_settings, :address_state_id, :integer
  end
end
