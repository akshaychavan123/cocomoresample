# This migration comes from bx_block_order_management (originally 20210419085730)
class AddColumnToDeliveryAddressOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :delivery_address_orders, :address_for, :string
  end
end
