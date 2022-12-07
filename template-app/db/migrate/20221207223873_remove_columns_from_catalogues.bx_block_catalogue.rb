# This migration comes from bx_block_catalogue (originally 20210325101801)
class RemoveColumnsFromCatalogues < ActiveRecord::Migration[6.0]
  def change
    remove_column :catalogues, :category_id
    remove_column :catalogues, :sub_category_id
  end
end
