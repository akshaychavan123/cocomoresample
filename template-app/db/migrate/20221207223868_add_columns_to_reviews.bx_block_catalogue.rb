# This migration comes from bx_block_catalogue (originally 20201103094103)
class AddColumnsToReviews < ActiveRecord::Migration[6.0]
  def change
    BxBlockCatalogue::Review.destroy_all
    add_reference :reviews, :account, null: false, foreign_key: true
  end
end
