# This migration comes from bx_block_wishlist (originally 20210326164012)
class CreateWishlists < ActiveRecord::Migration[6.0]
  def change
    create_table :wishlists do |t|
      t.references :account, null: false, foreign_key: true
      t.timestamps
    end
  end
end
