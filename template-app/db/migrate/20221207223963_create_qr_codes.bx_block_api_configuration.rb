# This migration comes from bx_block_api_configuration (originally 20210428085848)
class CreateQrCodes < ActiveRecord::Migration[6.0]
  def change
    create_table :qr_codes do |t|
      t.integer :code_type
      t.string :url
      t.timestamps
    end
  end
end
