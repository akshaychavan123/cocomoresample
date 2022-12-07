# This migration comes from bx_block_zipcode (originally 20210319064903)
class CreateBxBlockZipcodeZipcodes < ActiveRecord::Migration[6.0]
  def change
    create_table :zipcodes do |t|
      t.string :code
      t.boolean :activated, :default => true

      t.timestamps
    end
  end
end
