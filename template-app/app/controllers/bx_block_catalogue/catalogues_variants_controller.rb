module BxBlockCatalogue
  class CataloguesVariantsController < ApplicationController
    before_action :fetch_product, only: [:notify_product]

    def create
      variant = CatalogueVariant.new(variants_params)
      save_result = variant.save

      if save_result
        render json: CatalogueVariantSerializer.new(
          variant, serialization_options
        ).serializable_hash, status: :ok
      else
        render json: ErrorSerializer.new(variant).serializable_hash,
               status: :unprocessable_entity
      end
    end

    def notify_product
      if @product.present?
        @product.product_notifies.find_or_create_by(account_id: @current_user.id)
        render json: {
            success: true,
            data:
                {
                    product: CatalogueVariantSerializer.new(@product, @current_user),
                    product_notifies: @product.product_notifies
                }
        }, status: 200
      else
        render json: { message: "Product not found" }, status: 400
      end
    end

    def index
      serializer = CatalogueVariantSerializer.new(CatalogueVariant.all, serialization_options)

      render json: serializer, status: :ok
    end

    def variants_params
      params.permit(:catalogue_id,
                    :price,
                    :stock_qty,
                    :on_sale,
                    :sale_price,
                    :discount_price,
                    :decimal,
                    :length,
                    :breadth,
                    :height,
                    :images,
                    catalogue_variant_properties_attributes: [:id, :variant_id, :variant_property_id])
    end

    def serialization_options
      { params: { host: request.protocol + request.host_with_port } }
    end

    private

    def fetch_product
      @product = CatalogueVariant.find_by(id: params[:catalogue_variant_id])
    end
  end
end

