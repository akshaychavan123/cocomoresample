# This migration comes from bx_block_order_management (originally 20210921060626)
class AddTaxFieldsToCatalogue < ActiveRecord::Migration[6.0]
  def change
    add_column :catalogues, :tax_amount, :decimal
    add_column :catalogues, :price_including_tax, :decimal
    add_reference :catalogues, :tax, foreign_key: :true
  end
end
