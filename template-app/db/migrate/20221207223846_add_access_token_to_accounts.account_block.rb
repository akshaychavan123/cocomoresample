# This migration comes from account_block (originally 20210129083252)
class AddAccessTokenToAccounts < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :access_token, :text
  end
end
