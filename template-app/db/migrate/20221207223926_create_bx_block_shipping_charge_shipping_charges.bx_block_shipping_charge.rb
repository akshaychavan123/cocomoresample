# This migration comes from bx_block_shipping_charge (originally 20210319063549)
class CreateBxBlockShippingChargeShippingCharges < ActiveRecord::Migration[6.0]
  def change
    create_table :shipping_charges do |t|
      t.decimal :below
      t.decimal :charge
      t.timestamps
    end
  end
end
