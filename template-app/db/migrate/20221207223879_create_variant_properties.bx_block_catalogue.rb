# This migration comes from bx_block_catalogue (originally 20210902075914)
class CreateVariantProperties < ActiveRecord::Migration[6.0]
  def change
    create_table :variant_properties do |t|
      t.references :variant, null: false, foreign_key: true
      t.string :name

      t.timestamps
    end
  end
end
