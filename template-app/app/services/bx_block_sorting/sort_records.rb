module BxBlockSorting
  class SortRecords

    # Sample sort_params:
    # {
    #   "order_by": "price",
    #   "direction": "asc"
    # }
    def initialize(records, sort_params)
      @records = records
      @sort_params = sort_params || {}
      @sort_params[:direction] ||= "asc"
    end

    def call
      if @records.is_a?(Array)
        sort_array(@records, @sort_params)
      elsif order_by_exists?(@records, @sort_params[:order_by])
        sort_active_record(@records, @sort_params)
      else
        sort_by_method(@records, @sort_params)
      end
    end

    private

    def order_by_exists?(records, order_by)
      records.column_names.include?(order_by.to_s)
    end

    def sort_array(records, sort_params)
      return records if !sort_params.present? || !sort_params[:order_by].present?

      case sort_params[:direction]
      when "asc"
        records.sort {|a, b| a.send(sort_params[:order_by]) <=> b.send(sort_params[:order_by])}
      when "desc"
        records.sort {|a, b| -(a.send(sort_params[:order_by]) <=> b.send(sort_params[:order_by]))}
      else
        raise "Invalid direction for sorting."
      end
    end

    def sort_by_method(records, sort_params)
      sort_array(records.all, sort_params)
    end

    def sort_active_record(records, sort_params)
      return records.all if !sort_params.present? || !sort_params[:order_by].present?

      begin
        records.all.order("#{sort_params[:order_by]} #{sort_params[:direction]}")
      rescue ActiveRecord::StatementInvalid
        raise "Invalid order_by or direction for sorting."
      end
    end
  end
end
