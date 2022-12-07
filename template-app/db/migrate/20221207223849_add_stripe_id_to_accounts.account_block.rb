# This migration comes from account_block (originally 20210331074908)
class AddStripeIdToAccounts < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :stripe_id, :string
    add_column :accounts, :subscription_id, :string
    add_column :accounts, :subscription_date, :datetime
  end
end
