# This migration comes from bx_block_catalogue (originally 20201029141106)
class AddColumnToCatalogues < ActiveRecord::Migration[6.0]
  def change
    add_column :catalogues, :sold, :integer, default: 0
  end
end
