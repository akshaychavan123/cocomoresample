# This migration comes from bx_block_order_management (originally 20210818103208)
class AddFieldToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :is_subscribed, :boolean
  end
end
