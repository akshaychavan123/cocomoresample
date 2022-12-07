# This migration comes from bx_block_order_management (originally 20210330162187)
class AddColumnsToOrderItems < ActiveRecord::Migration[6.0]
  def change
    add_reference :order_items, :catalogue, null: false, foreign_key: true
    add_reference :order_items, :catalogue_variant, null: false, foreign_key: true
  end
end
