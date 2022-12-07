module BxBlockSearch
  class SearchController < ApplicationController
    def search
      if params[:per_page].present?
        search_results = RetrieveData.multi_search(params).take(params[:per_page].to_i)
      else
        search_results = RetrieveData.multi_search(params)
      end

      available_variants = {}

      property_ids = BxBlockCatalogue::Catalogue.active.where(availability: "in_stock").joins(catalogue_variants: :catalogue_variant_properties).pluck("catalogue_variant_properties.id")

      BxBlockCatalogue::CatalogueVariantProperty.joins(:catalogue_variant).where(id: property_ids).where("catalogue_variants.stock_qty > ?", 0).group_by(&:variant_id).each do |key, variants|
        variant_name = BxBlockCatalogue::Variant.find_by(id: key).name
        variants.each do |property|

          variant_property_name = BxBlockCatalogue::VariantProperty.find_by(id: property.variant_property_id).name rescue nil
          if !available_variants.has_key?(variant_name)
            available_variants[variant_name] = [{ variant_propert_name:variant_property_name, variant_property_id: property.variant_property_id }]
          elsif !available_variants[variant_name].include?({ variant_propert_name:variant_property_name, variant_property_id: property.variant_property_id }).present?
            available_variants[variant_name] += [{ variant_propert_name:variant_property_name, variant_property_id: property.variant_property_id }]
          end
        end
      end

      if search_results.empty?
        render json: {
          success: false,
          products: {
            data: []
          },
          message: "Sorry, no results found",
        }, status: 200
      else
        render json: {
          success: true,
          message: "#{search_results.size} results found.",
          products: SearchSerializer.new(search_results),
          available_variants: available_variants
        }, status: 200
      end
    end

    def recent_searches
      ids = []
      search_result = BxBlockSearch::RecentSearch.where(user_id: @current_user.id).pluck(:search_type, :search_id, :search_term).uniq
      search_result.each do |sr|
        ids << BxBlockSearch::RecentSearch.where(search_type: sr[0], search_id: sr[1], search_term: sr[2]).order(created_at: :desc)&.first&.id
      end
      searched_results = BxBlockSearch::RecentSearch.where(id: ids).select('id, search_term as name, search_id as class_id, search_type as class_name, created_at').sort_by do |s|
        s['created_at']
      end.reverse.first(5)

      if searched_results.any?
        render json: {
          search: searched_results,
        }, status: 200
      else
        render json: {
          success: false,
          message: "Sorry, no recent searches found",
        }, status: 200
      end

    end
  end
end
