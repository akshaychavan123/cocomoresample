module BxBlockCatalogue
  class CatalogueListingSerializer < BuilderBase::BaseSerializer
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

    attribute :images do |object, params|
      host = params[:host] || ''
      if object.attachments.present?
        BxBlockFileUpload::AttachmentSerializer.new(object.attachments, { params: params })
      end
    end

    attribute :sale_price do |object|
      object.sale_price&.round
    end

    attribute :reviews do |object, params|
      serializer = ReviewSerializer.new(object.reviews.where(is_published: true).order(created_at: :desc), { params: params })
      serializer.serializable_hash[:data]
    end

    attribute :cart_items do |object, params|
      if (user = params[:user]).nil?
        nil
      else
        result = {}
        user.orders.order_in_cart.last&.order_items&.each do |order_item|
          next unless order_item.catalogue_variant_id.in?(object.catalogue_variant_ids)
          result[order_item.catalogue_variant_id] = order_item.quantity
        end
        result
      end
    end

    attribute :wishlisted do |object, params|
      if (current_account = params[:user]).present?
        BxBlockWishlist::WishlistItem.where(catalogue_id: object.id).joins(:wishlist).where(wishlists: { account_id: current_account&.id.to_i }).any?
      end
    end

    attribute :is_subscription_available do |object|
      object.catalogue_subscriptions.present?
    end
  end
end
