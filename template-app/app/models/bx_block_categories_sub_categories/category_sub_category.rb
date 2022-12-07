module BxBlockCategoriesSubCategories
  class CategorySubCategory < ApplicationRecord
    self.table_name = :categories_sub_categories
    belongs_to :category
    belongs_to :sub_category
  end
end
