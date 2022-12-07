# This migration comes from bx_block_order_management (originally 20220407073217)
class CreateAddressStates < ActiveRecord::Migration[6.0]
  def change
    create_table :address_states do |t|
      t.string :name
      t.string :gst_code

      t.timestamps
    end
  end
end
