# This migration comes from bx_block_order_management (originally 20210921063657)
class AddTaxFieldsToCatalogueVariant < ActiveRecord::Migration[6.0]
  def change
    add_column :catalogue_variants, :tax_amount, :decimal
    add_column :catalogue_variants, :price_including_tax, :decimal
    add_reference :catalogue_variants, :tax, foreign_key: :true
  end
end
