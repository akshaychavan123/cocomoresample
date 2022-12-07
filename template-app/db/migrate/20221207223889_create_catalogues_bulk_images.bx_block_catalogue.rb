# This migration comes from bx_block_catalogue (originally 20220202110419)
class CreateCataloguesBulkImages < ActiveRecord::Migration[6.0]
  def change
    create_table :catalogues_bulk_images do |t|
      t.references :catalogue, null: false, foreign_key: true
      t.references :bulk_image, null: false, foreign_key: true
    end
  end
end
