# This migration comes from bx_block_order_management (originally 20210818122356)
class CreateSubscriptionOrders < ActiveRecord::Migration[6.0]
  def change
    create_table :subscription_orders do |t|
      t.bigint :order_item_id
      t.datetime :delivery_date
      t.integer :quantity
      t.string :status
    end
  end
end
