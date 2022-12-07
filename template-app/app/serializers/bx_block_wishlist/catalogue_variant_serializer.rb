# == Schema Information
#
# Table name: catalogue_variants
#
#  id                         :bigint           not null, primary key
#  catalogue_id               :bigint           not null
#  price                      :decimal(, )
#  stock_qty                  :integer
#  on_sale                    :boolean
#  sale_price                 :decimal(, )
#  discount_price             :decimal(, )
#  length                     :float
#  breadth                    :float
#  height                     :float
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  block_qty                  :integer
#
module BxBlockWishlist
  class CatalogueVariantSerializer < BuilderBase::BaseSerializer
    attributes :id, :catalogue_id,
               :price, :stock_qty, :on_sale, :sale_price, :discount_price,
               :length, :breadth, :height, :created_at, :updated_at, :is_default

    attribute :images do |object, params|
      host = params[:host] || ''

      if object.attachments.present?
        BxBlockFileUpload::AttachmentSerializer.new(object.attachments, { params: params })
      end
    end
  end
end
