module BxBlockCatalogue
  class CataloguesController < ApplicationController
    skip_before_action :validate_json_web_token, :only => [:price_value]
    skip_before_action :get_user, :only => [:price_value]
    before_action :load_catalogue, only: %i[show update destroy notify_product]

    def create
      catalogue = Catalogue.new(catalogue_params)
      save_result = catalogue.save

      if save_result
        process_images(catalogue, params[:images])

        catalogue.tags << Tag.where(id: params[:tags_id])

        process_variants_images(catalogue)

        render json: CatalogueSerializer.new(catalogue, serialization_options).serializable_hash,
               status: :ok
      else
        render json: ErrorSerializer.new(catalogue).serializable_hash,
               status: :unprocessable_entity
      end
    end

    def show
      return if @catalogue.nil?
      @cart = BxBlockOrderManagement::Order.find(params[:cart_id]) if params[:cart_id].present?
      # order_item = @current_user&.order_items&.where(catalogue: @catalogue).last
      order_item = @catalogue&.order_items.includes(:order).where(orders: {account_id: @current_user.id}).last

      product_reviews = @current_user.reviews.where(catalogue: @catalogue, order_item_id: order_item&.id)
      @can_review = ['returned', 'delivered'].include?(order_item&.order&.status.to_s) && product_reviews.blank?
      render json: CatalogueSerializer.new(@catalogue, serialization_options).serializable_hash,
             status: :ok
    end

    def index
      if params[:category_id].present?
        catalogues = BxBlockCatalogue::GetSubcatCatalogue.new(
          params[:category_id], ''
        ).call
      elsif params[:sub_category_id].present?
        catalogues = BxBlockCatalogue::GetSubcatCatalogue.new(
          '', params[:sub_category_id]
        ).call
      else
        catalogues = BxBlockCatalogue::GetSubcatCatalogue.new(
          '', ''
        ).call
      end

      all_catalogues = BxBlockCatalogue::Catalogue.active
      catalogues = catalogues.latest.page(params[:page] || 1).per(params[:per_page] || 10)

      render(json: { message: "No catalogue found" }, status: 200) && return unless (catalogues.any?)

      recommended_catalogues = catalogues.recommended.page(params[:page] || 1).per(params[:per_page] || 10) if params[:recommended].present?

      if all_catalogues.present? && params[:per_page].present?
        mod = all_catalogues.count % params[:per_page].to_i
        pages = all_catalogues.count / params[:per_page].to_i
        pages += 1 if mod > 0
      else
        pages = 0
      end

      available_variants = {}

      property_ids = catalogues.joins(catalogue_variants: :catalogue_variant_properties).pluck("catalogue_variant_properties.id")

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

      render(json: { message: "No catalogue found" }, status: 200) && return if !(catalogues.any?)
      render json: {
        data: {
          catalogue: CatalogueSerializer.new(catalogues, serialization_options(params[:template])),
          recommended_products: params[:recommended].present? ?
                                  CatalogueSerializer.new(recommended_catalogues, serialization_options(params[:template])) : [],
          available_variants: available_variants
        },
        meta: {
          pagination: {
            current_page: catalogues.current_page,
            next_page: catalogues.next_page,
            prev_page: catalogues.prev_page,
            total_pages: pages.present? ? pages : '',
            total_count: all_catalogues.length}
        }
      }, status: 200
    end

    def destroy
      return if @catalogue.nil?

      if @catalogue.destroy
        render json: { success: true }, status: :ok
      else
        render json: ErrorSerializer.new(@catalogue).serializable_hash,
               status: :unprocessable_entity
      end
    end

    def update
      return if @catalogue.nil?

      update_result = @catalogue.update(catalogue_params)

      update_tags
      process_images(@catalogue, params[:images])
      process_variants_images(@catalogue)

      if update_result
        render json: CatalogueSerializer.new(@catalogue, serialization_options).serializable_hash,
               status: :ok
      else
        render json: ErrorSerializer.new(@catalogue).serializable_hash,
               status: :unprocessable_entity
      end
    end

    def recommended_products
      recommended_products = Catalogue.active.latest.recommended.page(params[:page] || 1).per(params[:per_page] || 10)
      render json: RecommendedCatalogueListingSerializer.new(recommended_products, { params: { host: request.protocol + request.host_with_port, user: @current_user }, meta: { pagination: { current_page: recommended_products.current_page, next_page: recommended_products.next_page, prev_page: recommended_products.prev_page, total_pages: recommended_products.total_pages, total_count: recommended_products.length } } }), status: :ok
    end

    def products
      products = Catalogue.active.latest.page(params[:page] || 1).per(params[:per_page] || 10)
      render json: CatalogueListingSerializer.new(products, { params: { host: request.protocol + request.host_with_port, user: @current_user }, meta: { pagination: { current_page: products.current_page, next_page: products.next_page, prev_page: products.prev_page, total_pages: products.total_pages, total_count: products.length } } }), status: :ok
    end

    def products_and_variants
      catalogues = Catalogue.active.latest.page(params[:page] || 1).per(params[:per_page] || 10)

      available_variants = {}

      property_ids = catalogues.joins(catalogue_variants: :catalogue_variant_properties).pluck("catalogue_variant_properties.id")

      BxBlockCatalogue::CatalogueVariantProperty.joins(:catalogue_variant).where(id: property_ids).where("catalogue_variants.stock_qty > ?", 0).group_by(&:variant_id).each do |key, variants|
        variant_name = BxBlockCatalogue::Variant.find_by(id: key).name
        variants.each do |property|
          variant_property_name = BxBlockCatalogue::VariantProperty.find_by(id: property.variant_property_id).name rescue nil
          if !available_variants.has_key?(variant_name)
            available_variants[variant_name] = [{ variant_property_name: variant_property_name, variant_property_id: property.variant_property_id }]
          elsif !available_variants[variant_name].include?({ variant_property_name: variant_property_name, variant_property_id: property.variant_property_id }).present?
            available_variants[variant_name] += [{ variant_property_name: variant_property_name, variant_property_id: property.variant_property_id }]
          end
        end
      end

      render json: { data: { catalogues: CatalogueListingSerializer.new(catalogues, { params: { host: request.protocol + request.host_with_port, user: @current_user } }), available_variants: available_variants }, meta: { pagination: { current_page: catalogues.current_page, next_page: catalogues.next_page, prev_page: catalogues.prev_page, total_pages: catalogues.total_pages, total_count: catalogues.length } }
      }, status: :ok
    end

    def product_variants
      available_variants = {}

      property_ids = Catalogue.active.joins(catalogue_variants: :catalogue_variant_properties).pluck("catalogue_variant_properties.id")

      BxBlockCatalogue::CatalogueVariantProperty.joins(:catalogue_variant).where(id: property_ids).where("catalogue_variants.stock_qty > ?", 0).group_by(&:variant_id).each do |key, variants|
        variant_name = BxBlockCatalogue::Variant.find_by(id: key).name
        variants.each do |property|
          variant_property_name = BxBlockCatalogue::VariantProperty.find_by(id: property.variant_property_id).name rescue nil
          if !available_variants.has_key?(variant_name)
            available_variants[variant_name] = [{ variant_property_name: variant_property_name, variant_property_id: property.variant_property_id }]
          elsif !available_variants[variant_name].include?({ variant_property_name: variant_property_name, variant_property_id: property.variant_property_id }).present?
            available_variants[variant_name] += [{ variant_property_name: variant_property_name, variant_property_id: property.variant_property_id }]
          end
        end
      end

      render json: available_variants, status: :ok
    end

    def reindex
      if Catalogue.reindex
        render json: {
          message: "Reindexed successfully"
        }, status: 200
      else
        render json: {
          message: "Reindexing unsuccessful"
        }, status: 400
      end
    end

    def price_value
      min_value = BxBlockCatalogue::Catalogue.active.order("price ASC").first&.price
      max_value = BxBlockCatalogue::Catalogue.active.order("price DESC").first&.price
      render json: {
        success: true,
        data: {
          min_product_value: min_value.to_f,
          max_product_value: max_value.to_f
        }
      }, status: :ok
    end

    def notify_product
      if @catalogue.present?
        @catalogue.product_notifies.find_or_create_by(account_id: @current_user.id)
        render json: {
          success: true,
          data:
            {
              product: CatalogueSerializer.new(@catalogue, @current_user),
              product_notifies: @catalogue.product_notifies
            }
        }, status: 200
      else
        render json: { message: "Product not found" }, status: 400
      end
    end

    def available_price_update
      result = false
      BxBlockCatalogue::Catalogue.active.each do |catalogue|
        if catalogue.available_price == nil
          available_price = catalogue.on_sale == true ? catalogue.sale_price : catalogue.price
          if catalogue.update(available_price: available_price)
            result = true
          end
        end
      end
      if result == true
        render json: { message: "Available price updated" }, status: 200
      else
        render json: { message: "No product found with available price nil" }, status: 200
      end
    end

    private

    def load_catalogue
      @catalogue = Catalogue.active.find_by(id: params[:id])

      if @catalogue.nil?
        render json: {
          message: "Catalogue with id #{params[:id]} doesn't exists"
        }, status: :not_found
      end
    end

    def catalogue_params
      params.permit(
        :brand_id, :name, :sku, :description, :manufacture_date, :length, :breadth, :height,
        :stock_qty, :availability, :weight, :price, :recommended, :on_sale, :sale_price, :discount,
        catalogue_variants_attributes: [
          :id, :price, :stock_qty, :on_sale, :sale_price, :discount_price, :length, :breadth,
          :height, :_destroy, catalogue_variant_properties_attributes: [
          :id, :variant_id, :variant_property_id, :_destroy
        ]
        ]
      )
    end

    def update_tags
      tags = @catalogue.tags

      existing_tags_id = tags.map(&:id)
      params_tags = params[:tags_id] || []

      remove_ids = existing_tags_id - params_tags
      if remove_ids.size.positive?
        @catalogue.tags.delete(Tag.where(id: remove_ids))
      end

      add_ids = params_tags - existing_tags_id
      if add_ids.size.positive?
        @catalogue.tags << Tag.where(id: add_ids)
      end
    end

    def process_images(imagable, images_params)
      return unless images_params.present?

      images_to_attach = []
      images_to_remove = []

      images_params.each do |image_data|
        if image_data[:id].present? &&
          (image_data[:remove].present? || image_data[:data].present?)
          images_to_remove << image_data[:id]
        end

        if image_data[:data]
          images_to_attach.push(
            io: StringIO.new(Base64.decode64(image_data[:data])),
            content_type: image_data[:content_type],
            filename: image_data[:filename]
          )
        end
      end

      imagable.images.where(id: images_to_remove).purge if images_to_remove.size.positive?
      imagable.images.attach(images_to_attach) if images_to_attach.size.positive?
    end

    def process_variants_images(catalogue)
      variants = params[:catalogue_variants_attributes]

      return unless variants.present?

      variants.each_with_index do |v, index|
        next unless v[:images].present?

        process_images(catalogue.catalogue_variants[index], v[:images])
      end
    end

    def serialization_options(template = nil)
      request_hash = { params: { host: request.protocol + request.host_with_port, user: @current_user, cart: @cart,can_review: @can_review, catalogue_id: @catalogue&.id } }
      brand_setting = BxBlockStoreProfile::BrandSetting.first

      if params[:action] == 'index'
        request_hash[:params].merge!({
                                       ignore_similar_nesting: true, ignore_available_slots: true,
                                       ignore_available_subscription: true, ignore_catalogue_subscriptions: true,
                                       ignore_is_notify_product: true, ignore_is_subscription_available: true,
                                       ignore_preferred_delivery_slot: true, ignore_product_attributes: true,
                                       ignore_reviews: true, ignore_subscription_days_count: true,
                                       ignore_subscription_package: true, ignore_subscription_period: true,
                                       ignore_subscription_quantity: true, ignore_product_notified: true,
                                       ignore_average_rating: true, ignore_variants_in_cart: true
                                     })

        case template.to_s.downcase
        when 'prime'
          request_hash[:params].merge!({
                                         ignore_actual_price_including_tax: true, ignore_cart_items: true,
                                         ignore_cart_quantity: true
                                       })
        when 'essence'
          request_hash[:params].merge!({
                                         ignore_cart_items: true, ignore_cart_quantity: true
                                       })
        when 'bold'
          request_hash[:params].merge!({ ignore_wishlisted: true })
        when 'ultra'
          request_hash[:params].merge!({
                                         ignore_cart_items: true, ignore_cart_quantity: true
                                       })
        when 'mobile'
          request_hash[:params].merge!({
                                         ignore_preferred_delivery_slot: true, ignore_average_rating: false,
                                         ignore_reviews: false
                                       })
        end
      elsif params[:action] == 'show'
        request_hash[:params].merge!({
                                       ignore_product_notified: true, ignore_variants_in_cart: true
                                     })
        if template.to_s.downcase == 'mobile'
          request_hash[:params].merge!({
                                         ignore_product_notified: false, ignore_preferred_delivery_slot: true,
                                         ignore_subscription_days_count: true, ignore_variants_in_cart: false
                                       })
        end
      end
      request_hash
    end
  end
end


