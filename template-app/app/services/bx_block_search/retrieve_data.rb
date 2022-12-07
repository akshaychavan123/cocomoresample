module BxBlockSearch
  class RetrieveData
    def self.multi_search(params)
      search_results = []
      @params = params

      if @params[:query].present?
        catalogues = BxBlockCatalogue::Catalogue.active.where("lower(name) LIKE '%#{@params[:query].to_s.downcase}%'")
        if catalogues.present?
          catalogues.each do |catalogue|
            search_results << OpenStruct.new(
              type: 'Catalogue', id: catalogue.id, name: catalogue.name
            )
          end
        end

        sub_categories = BxBlockCategoriesSubCategories::SubCategory.where(
          "lower(name) LIKE '%#{@params[:query].to_s.downcase}%'"
        )
        if sub_categories.present?
          sub_categories.each do |sub_category|
            search_results << OpenStruct.new(
              type: 'SubCategory', id: sub_category.id, name: sub_category.name
            )
          end
        end

        categories = BxBlockCategoriesSubCategories::Category.where(
          "lower(name) LIKE '%#{@params[:query].to_s.downcase}%'"
        )
        if categories.present?
          categories.each do |category|
            search_results << OpenStruct.new(type: 'Category', id: category.id, name: category.name)
          end
        end

        brands = BxBlockCatalogue::Brand.where("lower(name) LIKE '%#{@params[:query].to_s.downcase}%'")
        if brands.present?
          brands.each do |brand|
            search_results << OpenStruct.new(type: 'Brand', id: brand.id, name: brand.name)
          end
        end
      else
        []
      end
      search_results
    end
  end
end
