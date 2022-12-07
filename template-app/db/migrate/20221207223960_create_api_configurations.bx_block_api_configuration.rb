# This migration comes from bx_block_api_configuration (originally 20210330122808)
class CreateApiConfigurations < ActiveRecord::Migration[6.0]
  def change
    create_table :api_configurations do |t|
      t.integer :configuration_type
      t.string :api_key
      t.string :api_secret_key
      t.string :application_id
      t.string :application_token
      t.string :ship_rocket_base_url
      t.string :ship_rocket_user_email
      t.string :ship_rocket_user_password
      t.timestamps
    end
  end
end
