# This migration comes from bx_block_order_management (originally 20210917092957)
class AddSubscriptionDiscountToOrderItem < ActiveRecord::Migration[6.0]
  def change
    add_column :order_items, :subscription_discount, :decimal
  end
end
