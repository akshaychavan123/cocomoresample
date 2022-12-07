module BxBlockWishlist
  class WishlistsController < ApplicationController
    before_action :fetch_product, only: [:create]
    before_action :fetch_wishlist, only: [:index]
    before_action :fetch_wishlist_item, only: [:remove_catalogue]

    def create
      render(json: { message: "Catalogue not found" }, status: 400) && return if @catalogue.nil?

      if CreateWishList.new(@catalogue, @catalogue_variant, @current_user).call
        render json: {
          success: true,
          message: "The item has been added to the wishlist",
          data:
          {
            wishlist: WishlistSerializer.new(@current_user.wishlist, { params: { user: @current_user} })
          }
        }, status: 200
      else
        render json: { message: "Could not add, maybe already present in wishlist" }, status: 400
      end
    end

    def index
      render(json: { wishlist: [] }) && return if @wishlist.nil?

      if @wishlist
        render json: {
          success: true,
          message: "",
          data:
          {
            wishlist: WishlistSerializer.new(@current_user.wishlist, {
              params: {
                user: @current_user, page: params[:page], per_page: params[:per_page]
              }
            }),
          }
        }, status: 200
      end
    end

    def remove_catalogue
      render(json: { message: "Wishlist item not found" }, status: 400) && return if @wishlist_item.nil?

      if DestroyWishList.new(@wishlist_item.id).call
        render json: {
          success: true,
          message: "The item has been removed from the wishlist",
          data:
            {
              wishlist: WishlistSerializer.new(@current_user.wishlist, {
                params: {
                  user: @current_user, page: params[:page], per_page: params[:per_page]
                }
              }),
            },
          token: [],
          meta: [],
          error: [],
          error_description: []
        }, status: 200
      end
    end

    private

    def fetch_product
      @catalogue = BxBlockCatalogue::Catalogue.active.find_by(id: params[:catalogue_id])
      @catalogue_variant = @catalogue.catalogue_variants.find_by(id: params[:catalogue_variant_id])
    end

    def fetch_wishlist
      @wishlist = Wishlist.find_or_create_by(account_id: @current_user.id)
    end

    def fetch_wishlist_item
      fetch_wishlist
      @wishlist_item = @wishlist.wishlist_items.find_by(catalogue_id: params[:catalogue_id], catalogue_variant_id: params[:catalogue_variant_id])
      params[:id] = params[:catalogue_id] if @wishlist_item.nil?
      @wishlist_item ||= WishlistItem.find_by(id: params[:id])
    end
  end
end
