# This migration comes from bx_block_catalogue (originally 20210916051742)
class AddVariantNumToCatalogueVariant < ActiveRecord::Migration[6.0]
  def change
    add_column :catalogue_variants, :variant_number, :integer
  end
end
