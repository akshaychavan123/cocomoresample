# This migration comes from account_block (originally 20210118131142)
class AddColumnToAccounts < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :user_name, :string
    add_column :accounts, :provider, :string
  end
end
