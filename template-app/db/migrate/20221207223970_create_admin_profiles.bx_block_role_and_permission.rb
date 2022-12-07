# This migration comes from bx_block_role_and_permission (originally 20210324070828)
class CreateAdminProfiles < ActiveRecord::Migration[6.0]
  def change
    create_table :admin_profiles do |t|
      t.string :name
      t.string :image
      t.string :password
      t.references :admin_user
      t.string :phone
      t.string :email
      t.timestamps
    end
  end
end
