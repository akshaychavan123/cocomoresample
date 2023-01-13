module BxBlockFilterItems
  class FilteringController < ApplicationController
    def index
      execute_queries
      # To keep order by consistent for frontend
      set_recommended_order

      render(json: { message: "No product found" }, status: 200) && return if @catalogues.empty?

      @catalogues = BxBlockSorting::SortRecords.new(@catalogues, params[:sort]).call if params[:sort].present?

      @catalogues = @catalogues.recommended if params[:sort].present? && params[:sort][:order_field] == "recommended"

      @catalogues = @catalogues.discounted_items if params[:discounted_items].present?

      paginate_records

      data = BxBlockCatalogue::CatalogueSerializer.new(@catalogues, serialization_options(params[:template])).serializable_hash
      data[:meta] = {
        pagination: {
          current_page: @catalogues.current_page,
          next_page: @catalogues.next_page,
          prev_page: @catalogues.prev_page,
          total_pages: @catalogues.total_pages,
          total_count: @catalogues.count
        }
      }

      render json: data, status: :ok
    end

    def product_filter
      execute_queries
      # To keep order by consistent for frontend
      set_recommended_order

      render(json: { message: "No product found" }, status: 200) && return if @catalogues.empty?

      @catalogues = BxBlockSorting::SortRecords.new(@catalogues, params[:sort]).call if params[:sort].present?

      @catalogues = @catalogues.recommended if params[:sort].present? && params[:sort][:order_field] == "recommended"

      @catalogues = @catalogues.discounted_items if params[:discounted_items].present?

      paginate_records

      data = BxBlockCatalogue::FilterCatalogueSerializer.new(@catalogues, { params: { user: @current_user }}).serializable_hash
      data[:meta] = {
        pagination: {
          current_page: @catalogues.current_page,
          next_page: @catalogues.next_page,
          prev_page: @catalogues.prev_page,
          total_pages: @catalogues.total_pages,
          total_count: @catalogues.count
        }
      }

      render json: data, status: :ok
    end

    private

    def serialization_options(template = nil)
      request_hash = {
        params: {
          host: request.protocol + request.host_with_port, user: @current_user,
          ignore_similar_nesting: true, ignore_available_slots: true,
          ignore_available_subscription: true, ignore_catalogue_subscriptions: true,
          ignore_is_notify_product: true, ignore_is_subscription_available: true,
          ignore_preferred_delivery_slot: true, ignore_product_attributes: true,
          ignore_reviews: true, ignore_subscription_days_count: true,
          ignore_subscription_package: true, ignore_subscription_period: true,
          ignore_subscription_quantity: true, ignore_product_notified: true,
          ignore_average_rating: true
        }
      }

      if template.to_s.downcase == 'mobile'
        request_hash[:params].merge!({
                                       ignore_average_rating: false, ignore_cart_items: true, ignore_cart_quantity: true,
                                       ignore_reviews: false
                                     })
      end

      request_hash
    end

    def execute_queries
      if params[:q].nil?
        @catalogues = BxBlockCatalogue::Catalogue.active
      else
        @catalogues = CatalogueFilter.new(::BxBlockCatalogue::Catalogue, params[:q]).call
        save_recent_search
      end
    end

    def save_recent_search
      return unless params[:q][:name]

      if params[:q][:id]
        id = params[:q][:id].first
        type = "Catalogue"
      elsif params[:q][:sub_category_id]
        id = params[:q][:sub_category_id].first
        type = "SubCategory"
      elsif params[:q][:category_id]
        id = params[:q][:category_id].first
        type = "Category"
      end

      # unless (BxBlockSearch::RecentSearch.all.pluck(:search_term).include? params[:q][:name]) &&
      # (BxBlockSearch::RecentSearch.all.pluck(:user_id).include? @current_user.id)
      BxBlockSearch::RecentSearch.create!(
        search_term: params[:q][:name],
        user_id: @current_user.id,
        search_id: id.to_i,
        search_type: type
      )
      # end
    end

    def set_recommended_order
      if params[:sort] && params[:sort][:order_by] == "recommended"
        params[:sort][:order_field] = "recommended"
        params[:sort].delete :order_by
      end
    end

    def paginate_records
      page_no = params[:page].to_i == 0 ? 1 : params[:page].to_i
      per_page = params[:per_page].to_i == 0 ? 10 : params[:per_page].to_i
      @catalogues = @catalogues.page(page_no).per(per_page)
    end
  end
end
