# This migration comes from bx_block_catalogue (originally 20210924091701)
class AddColumnToCatalogue < ActiveRecord::Migration[6.0]
  def change
    add_column :catalogues, :available_price, :float
  end
end
