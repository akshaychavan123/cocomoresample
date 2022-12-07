# This migration comes from bx_block_zipcode (originally 20210331050734)
class AddChargeToZipcode < ActiveRecord::Migration[6.0]
  def change
    add_column :zipcodes, :charge, :decimal, default: 0
    add_column :zipcodes, :price_less_than, :decimal, default: 0
  end
end
