module BxBlockShare
  class ShareController < BxBlockShare::ApplicationController
    def dl
      @catalogue = BxBlockCatalogue::Catalogue.active.find_by(id: params[:catalogue_id])
    end
  end
end
