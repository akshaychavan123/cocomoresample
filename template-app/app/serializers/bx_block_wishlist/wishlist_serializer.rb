module BxBlockWishlist
  class WishlistSerializer < BuilderBase::BaseSerializer
    attribute :wishlist_items do |wishlist, params|
      wishlist_items = wishlist.wishlist_items.active_catalogues.page(params[:page]).per(params[:per_page])
      WishlistItemSerializer.new(wishlist_items, { params: params, meta: { pagination: { current_page: wishlist_items.current_page, next_page: wishlist_items.next_page, prev_page: wishlist_items.prev_page, total_pages: wishlist_items.total_pages, total_count: wishlist_items.count }}}).serializable_hash
    end

    attribute :wishlist_count do |wishlist|
      return 0 if !wishlist.present?
      wishlist.wishlist_items.count
    end
  end
end
