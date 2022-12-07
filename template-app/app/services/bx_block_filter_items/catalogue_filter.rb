module BxBlockFilterItems
  class CatalogueFilter < ApplicationFilter

    private

    def query_string_for(attr_name, value)
      case attr_name
      when :price
        "price_including_tax >= #{value[:from]} AND price_including_tax <= #{value[:to]}"
      when :brand_id, :id
        ids = [*value].join(',')
        ids.empty? ? "1 = 0" : "#{attr_name} IN (#{ids})"
      when :tag_id
        sql_query = "SELECT catalogue_id FROM tags INNER JOIN catalogues_tags on " \
                    "tags.id = catalogues_tags.tag_id where tag_id = #{value[0].to_i}"
        result = ActiveRecord::Base.connection.exec_query(sql_query).rows
        catalogue_ids = result.map { |ids| ids.first }
        catalogue_ids.empty? ? "1 = 0" : "id IN (#{catalogue_ids.join(',')})"
      when :name
        sql_query = "SELECT catalogues.id FROM catalogues " \
                    "LEFT JOIN catalogues_sub_categories on " \
                      "catalogues.id = catalogues_sub_categories.catalogue_id " \
                    "LEFT JOIN sub_categories on " \
                      "catalogues_sub_categories.sub_category_id = sub_categories.id " \
                    "LEFT JOIN categories on categories.id = sub_categories.category_id " \
                      "where lower(catalogues.name) " \
                    "LIKE '%#{value.downcase}%' or lower(sub_categories.name) " \
                    "LIKE '%#{value.downcase}%' or lower(categories.name) " \
                    "LIKE '%#{value.downcase}%'"
        result = ActiveRecord::Base.connection.exec_query(sql_query).rows
        catalogue_ids = result.map { |ids| ids.first }
        catalogue_ids.empty? ? "1 = 0" : "id IN (#{catalogue_ids.join(',')})"
      else
        variant = BxBlockCatalogue::Variant.find_by(name: attr_name.to_s.camelize)
        if variant.present?
          ids = [*value].join(',')

          sql_query = "SELECT catalogue_id " \
                  "FROM catalogue_variant_properties " \
                  "where catalogue_variant_properties.variant_property_id  IN (#{ids}) AND catalogue_variant_properties.variant_id = #{variant.id} "

          result = ActiveRecord::Base.connection.exec_query(sql_query).rows
          catalogue_ids = result.map { |ids| ids.first }
          catalogue_ids.empty? ? "1 = 0" : "id IN (#{catalogue_ids.join(',')})"
        else
          ""
        end
      end
    end

    def query_string_for_categories_sub_categories(category_ids, sub_category_ids)
      ignore_cat_ids = BxBlockCategoriesSubCategories::SubCategory.where(id: sub_category_ids).pluck(:category_id)
      ignore_cat_ids.map!(&:to_s)
      subcat_ids =  (BxBlockCategoriesSubCategories::SubCategory.where(
        category_id: (category_ids - ignore_cat_ids)
      ).pluck(:id) + sub_category_ids).uniq
      product_ids = BxBlockCategoriesSubCategories::CataloguesSubCategory.where(
        sub_category_id: subcat_ids
      ).pluck(:catalogue_id).uniq
      product_ids.empty? ? "1 = 0" : "id IN (#{product_ids.join(",")})"
    end
  end
end
