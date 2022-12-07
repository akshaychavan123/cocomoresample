# This migration comes from bx_block_role_and_permission (originally 20210420052449)
class AddPasswordFieldsToAdminProfiles < ActiveRecord::Migration[6.0]
  def change
    add_column :admin_profiles, :password_confirmation, :string
    add_column :admin_profiles, :current_password, :string
  end
end
