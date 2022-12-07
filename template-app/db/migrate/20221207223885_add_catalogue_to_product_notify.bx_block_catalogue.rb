# This migration comes from bx_block_catalogue (originally 20210916082625)
class AddCatalogueToProductNotify < ActiveRecord::Migration[6.0]
  def change
    add_reference :product_notifies, :catalogue, foreign_key: :true
  end
end
