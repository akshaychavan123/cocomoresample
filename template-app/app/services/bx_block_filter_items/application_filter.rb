module BxBlockFilterItems
  class ApplicationFilter
    attr_accessor :active_record, :query_params, :date_format

    # Sample query_params:
    # {
    #   "price": {"from": 100, "to": 500},
    #   "category_id": 1,
    #   "brand_id": [1, 2],
    # }
    def initialize(active_record, query_params)
      if active_record == BxBlockCatalogue::Catalogue
        @active_record = active_record.active
      else
        @active_record = active_record
      end
      @query_params = query_params || {}
      @query_params = @query_params.permit!.to_h.deep_symbolize_keys if !@query_params.is_a?(Hash)
      @query_params.each do |k,v|
        @query_params[k] = v.map{|v| v.split(',')}.flatten.uniq if v.is_a?(Array)
      end
    end

    def call
      query_params.present? ? active_record.where(query_string) : []
    end

    private

    def query_string
      query_str = ""
      category_ids = query_params[:category_id]
      sub_category_ids = query_params[:sub_category_id]
      query_p = query_params.reject{ |k,v| [:category_id, :sub_category_id].include?(k.to_sym) }
      query_p.each_with_index do |(key, value), index|
        query_str += query_string_for(key, value)
        query_str += " AND " if (index < query_p.length - 1)
      end
      if category_ids.present? || sub_category_ids.present?
        query_str += " AND " if query_str.present?
        query_str += query_string_for_categories_sub_categories(category_ids || [], sub_category_ids || [])
      end

      query_str
    end

    def query_string_for(attr_name, value)
      raise "Must be implemented in derived class"
    end

    def query_string_for_categories_sub_categories(category_ids, sub_category_ids)
      raise "Must be implemented in derived class"
    end
  end
end
