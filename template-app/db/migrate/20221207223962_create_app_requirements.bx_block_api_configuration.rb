# This migration comes from bx_block_api_configuration (originally 20210420164936)
class CreateAppRequirements < ActiveRecord::Migration[6.0]
  def change
    create_table :app_requirements do |t|
      t.integer :requirement_type
      t.timestamps
    end
  end
end
