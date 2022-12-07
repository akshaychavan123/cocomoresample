# This migration comes from bx_block_catalogue (originally 20210903065519)
class AddVariantPropertyToCatalogueVariant < ActiveRecord::Migration[6.0]
  def change
    add_reference :catalogue_variants, :variant_property, foreign_key: :true
  end
end
