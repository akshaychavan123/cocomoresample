# This migration comes from bx_block_order_management (originally 20210930124858)
class ChangeDataTypeCountry < ActiveRecord::Migration[6.0]
  def up
    BxBlockOrderManagement::DeliveryAddress.update_all(country: 0)
    remove_column :delivery_addresses, :country
    add_column :delivery_addresses, :country, :integer, default: 0, null: false
  end

  def down
    remove_column :delivery_addresses, :country
    add_column :delivery_addresses, :country, :string
  end
end
