# This migration comes from account_block (originally 20210909125827)
class AddFullNameToSmsOtps < ActiveRecord::Migration[6.0]
  def change
    add_column :sms_otps, :full_name, :string
  end
end
