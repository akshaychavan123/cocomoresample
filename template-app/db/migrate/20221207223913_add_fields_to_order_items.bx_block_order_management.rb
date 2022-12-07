# This migration comes from bx_block_order_management (originally 20210818100238)
class AddFieldsToOrderItems < ActiveRecord::Migration[6.0]
  def change
    add_column :order_items, :subscription_package, :string
    add_column :order_items, :subscription_period, :string
    add_column :order_items, :subscription_quantity, :integer
    add_column :order_items, :preferred_delivery_slot, :string
  end
end
