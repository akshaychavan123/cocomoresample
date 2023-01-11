module BxBlockCatalogue
  class RecommendedCatalogueListingSerializer < BuilderBase::BaseSerializer
    attributes :id, :name, :description, :on_sale, :discount, :price_including_tax, :availability, :price

    attribute :stock_qty do |object, params|
      object.catalogue_variants.present? ? object.catalogue_variants.sum(:stock_qty) : object.stock_qty.to_i
    end

    attribute :available_variant do |object, params|
      default_variant = object.catalogue_variants.first_available_default
      available_variant = default_variant.present? ? default_variant : object.catalogue_variants.first_available
      CatalogueVariantSerializer.new(available_variant, { params: params }).serializable_hash
    end

    attribute :actual_price_including_tax do |object, params|
      object.price.present? ? object.price : 0
    end

    attribute :wishlisted do |object, params|
      if (account = params[:user]).present?
        BxBlockWishlist::WishlistItem.where(catalogue_id: object.id).joins(:wishlist).where(wishlists: { account_id: account&.id.to_i }).any?
      end
    end

    attribute :images do |object, params|
      host = params[:host] || ''
      if object.attachments.present?
        BxBlockFileUpload::AttachmentSerializer.new(object.attachments, { params: params })
      end
    end

    attribute :sale_price do |object|
      object.sale_price&.round
    end

    attribute :is_subscription_available do |object|
      object.catalogue_subscriptions.present?
    end
  end
end
