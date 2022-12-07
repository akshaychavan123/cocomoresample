module BxBlockAdmin
  class CataloguesController < ApplicationController
    def toggle_status
      catalogue = BxBlockCatalogue::Catalogue.find_by_id(toggle_params[:id])
      return if catalogue.nil?

      if toggle_params[:active] == 'true'
        catalogue.update(status: 'active')
      elsif toggle_params[:active] == 'false'
        catalogue.update(status: 'draft')
      end

      render json: { active: catalogue.reload.active?, success: !catalogue.errors.any?, id: catalogue.id }
    end

    private

    def toggle_params
      params.permit(:id, :active)
    end
  end
end
