# This migration comes from bx_block_wishlist (originally 20210908131532)
class AddCatalogueVariantToWishlistItem < ActiveRecord::Migration[6.0]
  def change
    add_reference :wishlist_items, :catalogue_variant, foreign_key: :true
  end
end
