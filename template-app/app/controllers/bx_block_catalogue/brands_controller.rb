module BxBlockCatalogue
  class BrandsController < ApplicationController
    before_action :get_brands, only: [:index]
    before_action :load_brand, only: [:destroy]

    def create
      brand = Brand.new(name: params[:name])
      save_result = brand.save

      if save_result
        render json: BrandSerializer.new(brand).serializable_hash,
               status: :ok
      else
        render json: ErrorSerializer.new(brand).serializable_hash,
               status: :unprocessable_entity
      end
    end

    def index
      render(json: { message: "No brands found" }, status: 200) && return if @brands.nil?

      render json: {
          data:
              {
                  brand: BrandSerializer.new(@brands),
                  maximum_price: @max_price,
                  minimum_price: @min_price
              }
      }, status: 200
    end

    def reindex
      if Brand.reindex
        render json: {
            message: "Reindexed successfully"
        }, status: 200
      else
        render json: {
            message: "Reindexing unsuccessful"
        }, status: 400
      end
    end

    def destroy
      render(json: { message: "Brand not found" }, status: 400) && return if @brand.nil?

      if @brand.destroy
        render json: {
            message: "Brand removed successfully"
        }, status: 200
      else
        render json: ErrorSerializer.new(@brand).serializable_hash,
               status: :unprocessable_entity
      end
    end

    private

    def get_brands
      @brands = Brand.all
      @max_price = Catalogue.active&.order("price_including_tax DESC")&.first&.price_including_tax&.round() || 0.0
      @min_price = Catalogue.active&.order("price_including_tax ASC")&.first&.price_including_tax&.to_i || 0.0
    end

    def load_brand
      @brand = Brand.find_by(id: params[:id])
    end
  end
end

