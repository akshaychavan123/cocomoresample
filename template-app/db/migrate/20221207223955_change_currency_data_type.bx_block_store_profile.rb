# This migration comes from bx_block_store_profile (originally 20210916090441)
class ChangeCurrencyDataType < ActiveRecord::Migration[6.0]
  def change
    change_column :brand_settings, :currency_type, :string
  end
end
