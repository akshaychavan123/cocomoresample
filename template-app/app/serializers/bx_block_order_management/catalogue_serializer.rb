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
module BxBlockOrderManagement
  class CatalogueSerializer < BuilderBase::BaseSerializer
    attributes :brand, :tags, :reviews,
               :name, :sku, :description, :manufacture_date,
               :length, :breadth, :height, :stock_qty,
               :availability, :weight, :price, :recommended,
               :on_sale, :sale_price, :discount

    attribute :wishlisted do |record, params|
      current_account = params[:user]
      current_account.nil? ? false : current_account.wishlist.wishlist_items.where(catalogue_id: record.id).any?
    end

    attribute :images do |object, params|
      host = params[:host] || ''

      if object.attachments.present?
        BxBlockFileUpload::AttachmentSerializer.new(object.attachments, { params: params })
      end
    end

    attribute :average_rating, &:average_rating

    attribute :catalogue_variants do |object, params|
      serializer = CatalogueVariantSerializer.new(object.catalogue_variants)
      serializer.serializable_hash[:data]
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
  end
end
