# This migration comes from bx_block_categories_sub_categories (originally 20210419083626)
class AddCategoryIdIntoSubCategories < ActiveRecord::Migration[6.0]
  def change
    add_reference :sub_categories, :category
  end
end
