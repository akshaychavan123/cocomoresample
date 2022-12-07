# This migration comes from bx_block_coupon_code_generator (originally 20210304094547)
class ChangeDatetimeTypeToDate < ActiveRecord::Migration[6.0]
  def change
    change_column :coupon_codes, :valid_from, :date
    change_column :coupon_codes, :valid_to, :date
  end
end
