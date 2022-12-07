module BxBlockCatalogue
  class VariantsController < ApplicationController
    before_action :fetch_product, only: [:notify_product]

    def create
      variant = Variant.new(variant_params)
      save_result = variant.save

      if save_result
        render json: VariantSerializer.new(
          variant, serialization_options
        ).serializable_hash, status: :ok
      else
        render json: ErrorSerializer.new(variant).serializable_hash,
               status: :unprocessable_entity
      end
    end

    def index
      serializer = VariantSerializer.new(Variant.all, serialization_options)

      render json: serializer, status: :ok
    end

    def variant_params
      params.permit(:name, variant_properties_attributes: [:name, :_destroy])
    end

    def serialization_options
      { params: { host: request.protocol + request.host_with_port } }
    end
  end
end
