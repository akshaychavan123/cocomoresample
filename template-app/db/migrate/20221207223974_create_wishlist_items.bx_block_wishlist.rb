# This migration comes from bx_block_wishlist (originally 20210326164013)
class CreateWishlistItems < ActiveRecord::Migration[6.0]
  def change
    create_table :wishlist_items do |t|
      t.references :catalogue
      t.references :wishlist, null: false, foreign_key: true
      t.timestamps
    end
  end
end
