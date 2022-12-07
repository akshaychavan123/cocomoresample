# This migration comes from bx_block_categories_sub_categories (originally 20210419084522)
class AddDisabledIntoCategories < ActiveRecord::Migration[6.0]
  def change
    add_column :categories, :disabled, :boolean, :default => false
    add_column :sub_categories, :disabled, :boolean, :default => false
  end
end
