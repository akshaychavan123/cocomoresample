# This migration comes from bx_block_catalogue (originally 20210310062052)
class AddOrderAndOrderItemIdToReview < ActiveRecord::Migration[6.0]
  def change
    # TODO: move this to order management block
    #add_reference :reviews, :order, null: true, foreign_key: true
    #add_reference :reviews, :order_item, null: true, foreign_key: true
    change_column :reviews, :catalogue_id, :bigint, null: true
  end
end
