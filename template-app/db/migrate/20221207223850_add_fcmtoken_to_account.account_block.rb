# This migration comes from account_block (originally 20210419083207)
class AddFcmtokenToAccount < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :fcm_token, :text
  end
end
