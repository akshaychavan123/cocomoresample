# This migration comes from bx_block_api_configuration (originally 20210621071153)
class CreateAppCategories < ActiveRecord::Migration[6.0]
  def change
    create_table :app_categories do |t|
      t.references :app_store_requirement
      t.string :product_title
      t.string :app_category
      t.string :review_username
      t.string :review_password
      t.string :review_notes
      t.string :app_type
      t.timestamps
    end
  end
end
