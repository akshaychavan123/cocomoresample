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
module BxBlockCatalogue
  class CatalogueVariantSerializer < BuilderBase::BaseSerializer
    attributes :id, :catalogue_id, :price, :stock_qty, :on_sale, :sale_price, :discount_price,
               :length, :breadth, :height, :is_default, :created_at, :updated_at,:tax_amount,:price_including_tax

    attribute :catalogue_variant_properties do |object|
      if object.catalogue_variant_properties.present?
        BxBlockCatalogue::CatalogueVariantPropertySerializer.new(object.catalogue_variant_properties).serializable_hash[:data]
      end
    end

    attribute :images do |object, params|
      host = params[:host] || ''

      if object.attachments.present?
        BxBlockFileUpload::AttachmentSerializer.new(object.attachments, { params: params })
      end
    end

    attribute :actual_price_including_tax do |object|
      object.price
    end

    attribute :cart_quantity do |object, params|
      if params[:user].present? && params[:user]&.orders&.present?
        current_user = params[:user]
        order_item = BxBlockOrderManagement::OrderItem.where(catalogue_id: object&.catalogue&.id, catalogue_variant_id: object&.id).joins(:order).where(orders: { account_id: current_user.id, status: 'in_cart' }).last

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

    attribute :is_notify_product do |object, params|
      if params[:user].present?
        user = params[:user]
        if user.product_notifies.present? && user.product_notifies.map(&:catalogue_variant_id).include?(object.id)
          true
        else
          false
        end
      end
    end
  end
end
