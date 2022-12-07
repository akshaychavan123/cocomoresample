# This migration comes from account_block (originally 20210122024210)
class AddColumnUidToAccount < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :uuid, :string
  end
end
