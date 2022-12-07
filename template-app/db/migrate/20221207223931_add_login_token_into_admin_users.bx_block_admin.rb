# This migration comes from bx_block_admin (originally 20210326072851)
class AddLoginTokenIntoAdminUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :admin_users, :login_token, :string
  end
end
