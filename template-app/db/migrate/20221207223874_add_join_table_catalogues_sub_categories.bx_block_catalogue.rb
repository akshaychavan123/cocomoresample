# This migration comes from bx_block_catalogue (originally 20210419083457)
class AddJoinTableCataloguesSubCategories < ActiveRecord::Migration[6.0]
  def change
    create_table :catalogues_sub_categories do |t|
      t.integer :catalogue_id
      t.integer :sub_category_id
    end
  end
end
