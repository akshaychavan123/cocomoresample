# This migration comes from account_block (originally 20210528103137)
class AddPhoneNumberToEmailOtp < ActiveRecord::Migration[6.0]
  def change
    add_column :email_otps, :phone_number, :string
  end
end
