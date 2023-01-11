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
              type: 'Catalogue', id: catalogue.id, name: catalogue.name, count: 1
            )
          end
        end

        sub_categories = BxBlockCategoriesSubCategories::SubCategory.where(
          "lower(name) LIKE '%#{@params[:query].to_s.downcase}%'"
        )
        if sub_categories.present?
          sub_categories.each do |sub_category|
            count = get_count("sub_categories", sub_category.id)
            search_results << OpenStruct.new(
              type: 'SubCategory', id: sub_category.id, name: sub_category.name, count: count
            )
          end
        end

        categories = BxBlockCategoriesSubCategories::Category.where(
          "lower(name) LIKE '%#{@params[:query].to_s.downcase}%'"
        )
        if categories.present?
          categories.each do |category|
            count = get_count("categories", category.id)
            search_results << OpenStruct.new(type: 'Category', id: category.id, name: category.name, count: count)
          end
        end

        brands = BxBlockCatalogue::Brand.where("lower(name) LIKE '%#{@params[:query].to_s.downcase}%'")
        if brands.present?
          brands.each do |brand|
            count = get_count("brands", brand.id)
            search_results << OpenStruct.new(type: 'Brand', id: brand.id, name: brand.name, count: count)
          end
        end
      else
        []
      end
      search_results
    end

    # Returns the count of the search result
    def self.get_count(resource_name, ids)
      query = "SELECT COUNT(*) FROM catalogues
                INNER JOIN catalogues_sub_categories AS csc on csc.catalogue_id = catalogues.id
                INNER JOIN sub_categories on sub_categories.id = csc.sub_category_id
                INNER JOIN categories on categories.id = sub_categories.category_id"
      ids = [ids].flatten.map(&:to_i)
      case resource_name
      when "sub_categories"
        query += " where sub_categories.id = ANY(ARRAY#{ids}::integer[])"
      when "categories"
        query += " where categories.id = ANY(ARRAY#{ids})"
      when "brands"
        query = "SELECT COUNT(*) FROM catalogues where catalogues.brand_id = ANY(ARRAY#{ids})"
      else
        query = ""
      end
      result = BxBlockCatalogue::Catalogue.find_by_sql(query).first
      result.try(:count) || 0
    end

  end
end
