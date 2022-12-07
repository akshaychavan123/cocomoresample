# This migration comes from bx_block_order_management (originally 20210330162198)
class CreateTaxes < ActiveRecord::Migration[6.0]
  def change
    create_table :taxes do |t|
      t.float :tax_percentage

      t.timestamps
    end
  end
end
