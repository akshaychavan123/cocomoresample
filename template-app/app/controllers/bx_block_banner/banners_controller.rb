module BxBlockBanner
  class BannersController < ApplicationController

    before_action :fetch_banner, only: [:show]
    before_action :load_banners, only: [:index]

    def show
      render(json: { message: "No banner found" }, status: 400) && return if @banner.nil?

      if @banner
        render json: {
            Banner: BannerSerializer.new(@banner),
        }, status: 200
      end
    end

    def index
      render(json: { message: "No banners found" }, status: 200) && return if @banners.nil?

      render json: {
          data: {
              banners: BannerSerializer.new(@banners)
          }
      }, status: 200
    end

    def web_banners_list
      banners = BxBlockBanner::Banner.where(web_banner: true)
      render json: {
          data: {
              banners: BannerSerializer.new(banners)
          }
      }, status: 200
    end

    def mobile_banners_list
      banners = BxBlockBanner::Banner.where.not(web_banner: true)
      render json: {
          data: {
              banners: BannerSerializer.new(banners)
          }
      }, status: 200
    end

    private

    def fetch_banner
      @banner = BxBlockBanner::Banner.find_by(id: params[:id])
    end

    def load_banners
      @banners = BxBlockBanner::Banner.all
    end
  end
end
