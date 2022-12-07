module BxBlockApiConfiguration
  class AppStoreRequirementsController < ApplicationController

    def index
      app_store_requirement = AppStoreRequirement.last
      response = app_store_requirement.get_json_response

      render json: {
          message: 'No app store requirement is present'
      } and return unless app_store_requirement.present?
      render json: {
          message: "",
          app_store_requirement: response, status: :ok}
    end
  end
end
