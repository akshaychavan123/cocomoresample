# This migration comes from bx_block_catalogue (originally 20220202080754)
class CreateBulkImages < ActiveRecord::Migration[6.0]
  def change
    create_table :bulk_images do |t|
      t.timestamps
    end
  end
end
