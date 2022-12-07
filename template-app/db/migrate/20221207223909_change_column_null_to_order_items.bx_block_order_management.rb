# This migration comes from bx_block_order_management (originally 20210419083923)
class ChangeColumnNullToOrderItems < ActiveRecord::Migration[6.0]
  def change
    change_column_null :order_items, :catalogue_variant_id, true
  end
end
