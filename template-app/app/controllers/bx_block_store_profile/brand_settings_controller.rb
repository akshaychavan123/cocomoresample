module BxBlockStoreProfile
  class BrandSettingsController < ApplicationController
    def index
      brand_setting = BxBlockStoreProfile::BrandSetting.last
      response = brand_setting.nested_response_hash

      render json: {
          message: 'No Brand Setting is present'
      } and return unless brand_setting.present?
      render json: {
          message: "",
          brand_setting: response, status: :ok}
    end

    def change_site_title
      @brand_setting = BxBlockStoreProfile::BrandSetting.last
    end
  end
end
