# This migration comes from bx_block_catalogue (originally 20210302082958)
class CreateVariantTypes < ActiveRecord::Migration[6.0]
  def change
    create_table :variant_types do |t|
      t.string :variant_type
      t.string :value
      t.references :catalogue, foreign_key: true
      t.references :catalogue_variant, foreign_key: true

      t.timestamps
    end
  end
end
