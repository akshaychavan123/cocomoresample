# This migration comes from account_block (originally 20201218094707)
class AddFullNameToAccount < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :full_name, :string
  end
end
