# This migration comes from bx_block_order_management (originally 20220421095908)
class AddTaxAmountAndBasicAmountToOrderItems < ActiveRecord::Migration[6.0]
  def change
    add_column :order_items, :basic_amount, :decimal
    add_column :order_items, :tax_amount, :decimal
  end
end
