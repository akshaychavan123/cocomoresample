# This migration comes from bx_block_order_management (originally 20220407073612)
class AddAddressStateIntoBrandSetting < ActiveRecord::Migration[6.0]
  def change
    add_column :delivery_addresses, :address_state_id, :integer
  end
end
