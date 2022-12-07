# This migration comes from bx_block_catalogue (originally 20220603061105)
class AddIndexToStatusToCatalogues < ActiveRecord::Migration[6.0]
  def change
    add_index :catalogues, :status
  end
end
