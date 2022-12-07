# This migration comes from bx_block_admin (originally 20220520112511)
# This migration comes from active_storage
class CreateActiveStorageVariantRecords < ActiveRecord::Migration[6.0]
  def change
    create_table :active_storage_variant_records do |t|
      t.belongs_to :blob, null: false, index: false
      t.string :variation_digest, null: false

      t.index %i[ blob_id variation_digest ], name: "index_active_storage_variant_records_uniqueness", unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end
  end
end
