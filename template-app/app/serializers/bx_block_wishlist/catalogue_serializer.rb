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
module BxBlockWishlist
  class CatalogueSerializer < BuilderBase::BaseSerializer
    attributes :brand, :tags, :reviews,
               :name, :sku, :description, :manufacture_date,
               :length, :breadth, :height, :stock_qty,
               :availability, :weight, :price, :price_including_tax, :recommended,
               :on_sale, :sale_price, :discount

    attribute :actual_price_including_tax do |object|
      object.price
    end

    attribute :wishlisted do |object, params|
      current_account = params[:user]
      current_account.nil? ? false : current_account.wishlist.wishlist_items.where(catalogue_id: object.id).any?
    end

    attribute :is_subscription_available do |object|
      object.catalogue_subscriptions.present?
    end

    attribute :images do |object, params|
      host = params[:host] || ''

      if object.attachments.present?
        BxBlockFileUpload::AttachmentSerializer.new(object.attachments, { params: params })
      end
    end

    attribute :default_variant do |object|
      object.catalogue_variants.find_by(is_default: true) || object.catalogue_variants.first
    end

    attribute :average_rating, &:average_rating

    attribute :catalogue_variants do |object, params|
      serializer = CatalogueVariantSerializer.new(object.catalogue_variants)
      serializer.serializable_hash[:data]
    end

    attribute :cart_items do |object, params|
      if params[:user].nil?
        nil
      else
        result = {}
        params[:user].orders.order_in_cart.last&.order_items&.each do |order_item|
          next unless order_item.catalogue_variant_id.in?(object.catalogue_variant_ids)
          result[order_item.catalogue_variant_id] = order_item.quantity
        end
        result
      end
    end

    attribute :category do |object, params|
      options = {}
      if object.sub_categories.present?
        object.sub_categories.map{ |subcat|
          options[:params] = {subcat: subcat}
          options
          BxBlockCategoriesSubCategories::CategorySerializer.new(subcat.category, options)
        }
      end
    end

    attribute :cart_quantity do |object, params|
      if params[:user].present? && params[:user]&.orders&.present?
        current_user = params[:user]
        order = current_user.orders.where(status: 'in_cart').last
        order_item = order.order_items.where(catalogue_id: object&.id).last  if order.present?
        if order_item.present?
          cart_quantity = order_item.quantity
        else
          cart_quantity =  nil
        end
      else
        cart_quantity =  nil
      end
      cart_quantity
    end
  end
end
