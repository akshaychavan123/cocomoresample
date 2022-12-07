# This migration comes from bx_block_catalogue (originally 20201224134508)
class CreateProductNotifies < ActiveRecord::Migration[6.0]
  def change
    create_table :product_notifies do |t|
      t.references :catalogue_variant, foreign_key: true
      t.references :account, foreign_key: true
      t.timestamps
    end
  end
end
