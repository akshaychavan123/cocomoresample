# This migration comes from bx_block_catalogue (originally 20220426065411)
class AddStatusToCatalogues < ActiveRecord::Migration[6.0]
  def change
    add_column :catalogues, :status, :integer, default: 0
  end
end
