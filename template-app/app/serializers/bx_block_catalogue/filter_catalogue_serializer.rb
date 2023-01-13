module BxBlockCatalogue
  class FilterCatalogueSerializer < BuilderBase::BaseSerializer
    attributes :id, :name, :on_sale, :discount, :price_including_tax, :price, :sale_price, :availability

    attribute :has_catalogue_variants do |object|
      object.catalogue_variants.present?
    end

    attribute :stock_qty do |object, params|
      object.catalogue_variants.present? ? object.catalogue_variants.sum(:stock_qty) : object.stock_qty.to_i
    end

    attribute :actual_price_including_tax do |object, params|
      object.price.present? ? object.price : 0
    end

    attribute :wishlisted do |object, params|
      current_account = params[:user]
      BxBlockWishlist::WishlistItem.where(catalogue_id: object.id).joins(:wishlist).where(wishlists: { account_id: current_account&.id.to_i }).any?
    end

    attribute :images do |object, params|
      if object.attachments.present?
        BxBlockFileUpload::AttachmentSerializer.new(object.attachments, { params: params })
      end
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

    attribute :cart_quantity do |object, params|
      if params[:user].present? && params[:user]&.orders&.present?
        current_user = params[:user]
        order = current_user.orders.where(status: 'in_cart').last
        order_item = order.order_items.where(catalogue_id: object&.id, subscription_quantity: nil).last  if order.present?
        if order_item.present?
          cart_quantity = order_item.quantity
        else
          cart_quantity =  nil
        end
      else
        cart_quantity = nil
      end
      cart_quantity
    end

    attribute :is_subscription_available do |object|
      object.catalogue_subscriptions.present?
    end
  end
end
