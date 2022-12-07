# This migration comes from account_block (originally 20201228124451)
class AddGuestToAccounts < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :guest, :boolean
  end
end
