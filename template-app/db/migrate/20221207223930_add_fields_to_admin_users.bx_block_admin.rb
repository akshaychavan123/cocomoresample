# This migration comes from bx_block_admin (originally 20210324055425)
class AddFieldsToAdminUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :admin_users, :phone_number, :string
    add_column :admin_users, :role, :integer
    add_column :admin_users, :activated, :boolean, :default => false, :null => false
    add_index  :admin_users, :activated
    add_column :admin_users, :permissions, :text, array: true, default: []
    add_column :admin_users, :name, :string
    add_column :admin_users, :sign_in_count, :integer
    add_column :admin_users, :current_sign_in_at, :datetime
    add_column :admin_users, :last_sign_in_at, :datetime
    add_column :admin_users, :current_sign_in_ip, :inet
    add_column :admin_users, :last_sign_in_ip, :inet
  end
end
