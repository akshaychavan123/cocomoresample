module BxBlockWishlist
  class WishlistItemSerializer < BuilderBase::BaseSerializer
    attribute :id do |wishlist_item, params|
      CatalogueSerializer.new(wishlist_item.catalogue, { params: params })
    end

    attribute :catalogue_variant do |wishlist_item, params|
      CatalogueVariantSerializer.new(wishlist_item.catalogue_variant, { params: params })
    end
  end
end
