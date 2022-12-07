module BxBlockWishlist
  class CreateWishList

    def initialize(catalogue, catalogue_variant, account)
      @catalogue = catalogue
      @catalogue_variant = catalogue_variant
      @account = account
    end

    def call
      Wishlist.create!(account_id: @account.id) if @account.wishlist.nil?
      @account.reload if @account.wishlist.nil?
      unless @account.wishlist.catalogue_ids.index(@catalogue.id)
        WishlistItem.create(catalogue_id: @catalogue&.id, wishlist_id: @account.wishlist&.id, catalogue_variant_id: @catalogue_variant&.id)
      end
    end
  end
end
