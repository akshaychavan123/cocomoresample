# == Schema Information
#
# Table name: catalogues
#
#  id               :bigint           not null, primary key
#  category_id      :bigint           not null
#  sub_category_id  :bigint           not null
#  brand_id         :bigint
#  name             :string
#  sku              :string
#  description      :string
#  manufacture_date :datetime
#  length           :float
#  breadth          :float
#  height           :float
#  availability     :integer
#  stock_qty        :integer
#  weight           :decimal(, )
#  price            :float
#  recommended      :boolean
#  on_sale          :boolean
#  sale_price       :decimal(, )
#  discount         :decimal(, )
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  block_qty        :integer
#  sold             :integer          default(0)
#
module BxBlockCatalogue
  class CatalogueSerializer < BuilderBase::BaseSerializer
    attributes :name, :description, :on_sale, :discount, :sku, :price_including_tax, :height,
               :availability

    attribute :stock_qty do |object, params|
      object.catalogue_variants.present? ? object.catalogue_variants.sum(:stock_qty) : object.stock_qty.to_i
    end

    attribute :default_variant do |object, params|
      variant = object.catalogue_variants.find_by(is_default: true) || object.catalogue_variants.first
      DefaultCatalogueVariantSerializer.new(variant)
    end

    attribute :actual_price_including_tax do |object, params|
      if params[:ignore_actual_price_including_tax]
        nil
      else
        object.price
      end
    end

    attribute :cart_quantity do |object, params|
      if params[:ignore_cart_quantity]
        nil
      else
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
    end

    attribute :subscription_quantity do |object, params|
      if params[:ignore_subscription_quantity]
        nil
      else
        user = params[:user]
        if user.present? && user.orders.present?
          order = user.orders.where(status: 'in_cart').last
          order_item = order.order_items.where(catalogue_id: object.id).where.not(subscription_quantity: nil).last if order.present?
          order_item.subscription_quantity if order_item.present?
        end
      end
    end

    attribute :subscription_package do |object, params|
      if params[:ignore_subscription_package]
        nil
      else
        user = params[:user]
        if user.present? && user.orders.present?
          order = user.orders.where(status: 'in_cart').last
          order_item = order.order_items.where(catalogue_id: object.id).where.not(subscription_quantity: nil).last  if order.present?
          order_item.subscription_package if order_item.present?
        end
      end
    end

    attribute :subscription_period do |object, params|
      if params[:ignore_subscription_period]
        nil
      else
        user = params[:user]
        if user.present? && user.orders.present?
          order = user.orders.where(status: 'in_cart').last
          order_item = order.order_items.where(catalogue_id: object.id).where.not(subscription_quantity: nil).last if order.present?
          order_item.subscription_period if order_item.present?
        end
      end
    end

    attribute :subscription_days_count do |object, params|
      if params[:ignore_subscription_days_count]
        nil
      else
        user = params[:user]
        if user.present? && user.orders.present?
          order = user.orders.where(status: 'in_cart').last
          order_item = order.order_items.where(catalogue_id: object.id).where.not(subscription_quantity: nil).last if order.present?
          if order_item.present?
            item_count = ((Date.tomorrow + order_item.subscription_period.to_i.months) - Date.tomorrow).to_i
            if order_item.subscription_package.to_s.downcase == 'daily'
              order_item_quantity = item_count * order_item.subscription_quantity
            elsif order_item.subscription_package.to_s.downcase == 'weekly'
              order_item_quantity = (item_count / 7 ) * order_item.subscription_quantity
            elsif order_item.subscription_package.to_s.downcase == 'monthly'
              order_item_quantity = order_item.subscription_period.to_i * order_item.subscription_quantity
            end
          end
        end
      end
    end

    attribute :preferred_delivery_slot do |object, params|
      if params[:ignore_preferred_delivery_slot]
        nil
      else
        user = params[:user]
        if user.present? && user.orders.present?
          order = user.orders.where(status: 'in_cart').last
          order_item = order.order_items.where(catalogue_id: object.id).where.not(preferred_delivery_slot: nil).last if order.present?
          order_item.preferred_delivery_slot if order_item.present?
        end
      end
    end

    attribute :wishlisted do |object, params|
      if params[:ignore_wishlisted]
        nil
      else
        current_account = params[:user]
        BxBlockWishlist::WishlistItem.where(catalogue_id: object.id).joins(:wishlist).where(wishlists: { account_id: current_account&.id.to_i }).any?
      end
    end

    attribute :product_notified do |object, params|
      if params[:ignore_product_notified]
        nil
      else
        current_account = params[:user]
        BxBlockCatalogue::ProductNotify.where(
          catalogue_variant_id: object.catalogue_variants.pluck(:id), account_id: current_account&.id.to_i
        ).any?
      end
    end

    attribute :cart_items do |object, params|
      if params[:ignore_cart_items]
        []
      else
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
    end

    attribute :average_rating do |object, params|
      if params[:ignore_average_rating]
        nil
      else
        object.average_rating
      end
    end

    attribute :images do |object, params|
      host = params[:host] || ''
      if object.attachments.present?
        BxBlockFileUpload::AttachmentSerializer.new(object.attachments, { params: params })
      end
    end

    attribute :product_attributes do |object, params|
      if params[:ignore_product_attributes]
        {}
      else
        if object.catalogue_variants.present?
          p_variants = object.catalogue_variants
          _hash = {}
          Variant.all.each do |variant|
            _hash["#{variant.name}"] = p_variants.map{|pv| pv.catalogue_variant_properties.where(variant_id: variant.id).map{|pvp| {name: pvp.variant_property.name, variant_property_id: pvp.variant_property_id}}}.flatten.uniq
          end
          _hash
        end
      end
    end

    attribute :deep_link do |object|
      "https://#{ENV['HOST_URL']}/share/share/dl?catalogue_id=#{object.id}"
    end

    attribute :catalogue_variants do |object, params|
      serializer = CatalogueVariantSerializer.new(
        object.catalogue_variants, { params: params }
      )
      serializer.serializable_hash[:data]
    end

    attribute :similar_products do |object, params|
      if params[:ignore_similar_nesting]
        []
      else
        subcat_ids = object.sub_categories.pluck(:id)
        catalogue_ids = BxBlockCategoriesSubCategories::CataloguesSubCategory.where(
          sub_category_id: subcat_ids
        ).pluck(:catalogue_id).uniq
        catalogue_ids.delete(object.id)
        catalogues = BxBlockCatalogue::Catalogue.active.where(id: catalogue_ids).in_stock
        params[:ignore_similar_nesting] = true
        CatalogueSerializer.new(catalogues.order('created_at desc').first(10), {params: params})
      end
    end

    attribute :reviews do |object, params|
      if params[:ignore_reviews]
        []
      else
        serializer = BxBlockCatalogue::ReviewSerializer.new(object.reviews.where(is_published: true).order(created_at: :desc), { params: params })
        serializer.serializable_hash[:data]
      end
    end

    attribute :catalogue_subscriptions do |object, params|
      if params[:ignore_catalogue_subscriptions]
        []
      else
        BxBlockCatalogue::CatalogueSubscriptionSerializer.new(object.catalogue_subscriptions).serializable_hash[:data]
      end
    end

    attribute :is_subscription_available do |object, params|
      if params[:ignore_is_subscription_available]
        nil
      else
        object.catalogue_subscriptions.present?
      end
    end

    attribute :available_subscription do |object, params|
      if params[:ignore_available_subscription]
        {}
      else
        _hash = {}
        object.catalogue_subscriptions.all.each do |subscription|
          _hash["#{subscription.subscription_package}"] = object.catalogue_subscriptions.where(subscription_package: subscription.subscription_package).map(&:subscription_period)
        end
        _hash
      end
    end

    attribute :available_slots do |object, params|
      if params[:ignore_available_slots]
        {}
      else
        morning_slots = object.catalogue_subscriptions.map{|ps| JSON.parse(ps.morning_slot).map{|s| s.to_s.gsub('_', ' ')}}.uniq.first
        evening_slots = object.catalogue_subscriptions.map{|ps| JSON.parse(ps.evening_slot).map{|s| s.to_s.gsub('_', ' ')}}.uniq.first
        slots = {}
        slots["morning_slots"] = morning_slots
        slots["evening_slots"] = evening_slots
        slots
      end
    end

    attribute :is_notify_product do |object, params|
      if params[:ignore_is_notify_product]
        nil
      else
        if params[:user].present?
          user = params[:user]
          if user.product_notifies.present? && user.product_notifies.map(&:catalogue_id).include?(object.id)
            true
          else
            false
          end
        end
      end
    end

    attribute :variants_in_cart do |object, params|
      if params[:ignore_variants_in_cart]
        nil
      else
        variants_id_in_cart = params[:cart]&.order_items&.pluck(:catalogue_variant_id) || []
        variants_id = object&.catalogue_variants&.pluck(:id) || []
        variants_id_in_cart & variants_id
      end
    end
  end
end
