module BxBlockCategoriesSubCategories
  class CataloguesSubCategory < BxBlockCategoriesSubCategories::ApplicationRecord
    self.table_name = "catalogues_sub_categories"
    belongs_to :catalogue, class_name: 'BxBlockCatalogue::Catalogue'
    belongs_to :sub_category
  end
end
