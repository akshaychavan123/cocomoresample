# This migration comes from bx_block_order_management (originally 20210419083256)
class AddFieldsToReviews < ActiveRecord::Migration[6.0]
  def change
    add_reference :reviews, :order, null: true, foreign_key: true
    add_reference :reviews, :order_item, null: true, foreign_key: true
    add_column :reviews, :is_published, :boolean
  end
end
