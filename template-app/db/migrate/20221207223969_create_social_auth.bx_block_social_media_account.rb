# This migration comes from bx_block_social_media_account (originally 20210401143047)
class CreateSocialAuth < ActiveRecord::Migration[6.0]
  def change
    create_table :social_auths do |t|
      t.string :provider
      t.string :uid
      t.string :secret
      t.references :account, null: false, foreign_key: true
      t.string :token
      t.string :display_name

      t.timestamps
    end
  end
end
