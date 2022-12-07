# This migration comes from bx_block_catalogue (originally 20210903070041)
class CreateCatalogueVariantProperties < ActiveRecord::Migration[6.0]
  def change
    create_table :catalogue_variant_properties do |t|
      t.references :catalogue, null: false, foreign_key: true
      t.references :catalogue_variant, null: false, foreign_key: true
      t.references :variant, null: false, foreign_key: true
      t.references :variant_property, null: false, foreign_key: true

      t.timestamps
    end
  end
end
