module BxBlockSorting
  class SortingController < ApplicationController
    def index
      @catalogues = SortRecords.new(::BxBlockCatalogue::Catalogue, params[:sort]).call

      render json: ::BxBlockCatalogue::CatalogueSerializer
                       .new(@catalogues, serialization_options)
                       .serializable_hash
    end

    private

    def serialization_options
      { params: { host: request.protocol + request.host_with_port } }
    end

  end
end
