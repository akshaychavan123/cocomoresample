# This migration comes from bx_block_order_management (originally 20210330162199)
class AddColumnsInOrder < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :length, :string
    add_column :orders, :breadth, :string
    add_column :orders, :height, :string
    add_column :orders, :weight, :string
  end
end
