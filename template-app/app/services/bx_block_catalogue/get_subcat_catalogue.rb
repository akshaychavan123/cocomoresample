module BxBlockCatalogue
  class GetSubcatCatalogue

    def initialize(category_id='', sub_category_id='')
      @category = BxBlockCategoriesSubCategories::Category.find_by(
        id: category_id
      ) if category_id.present?
      @sub_category = BxBlockCategoriesSubCategories::SubCategory.find_by(
        id: sub_category_id
      ) if sub_category_id.present?
    end

    def call
      if @category.present?
        catalogues = []
        @category.sub_categories.each do |subcat|
          catalogues = catalogues + subcat.catalogues.pluck(:id)
        end
        return BxBlockCatalogue::Catalogue.active.where(id: catalogues.uniq)
      elsif @sub_category.present?
        return @sub_category.catalogues
      else
        return BxBlockCatalogue::Catalogue.active
      end
    end
  end
end
