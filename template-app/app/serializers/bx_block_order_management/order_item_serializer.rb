# == Schema Information
#
# Table name: order_items
#
#  id                      :bigint           not null, primary key
#  order_id                :bigint           not null
#  quantity                :integer
#  unit_price              :decimal(, )
#  total_price             :decimal(, )
#  old_unit_price          :decimal(, )
#  status                  :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  catalogue_id            :bigint           not null
#  catalogue_variant_id    :bigint           not null
#  order_status_id         :integer
#  placed_at               :datetime
#  confirmed_at            :datetime
#  in_transit_at           :datetime
#  delivered_at            :datetime
#  cancelled_at            :datetime
#  refunded_at             :datetime
#  manage_placed_status    :boolean          default(FALSE)
#  manage_cancelled_status :boolean          default(FALSE)
#
module BxBlockOrderManagement
  class OrderItemSerializer < BuilderBase::BaseSerializer
    attributes :id, :quantity, :total_price, :catalogue_id, :catalogue_variant_id,
               :cancelled_at, :subscription_quantity, :subscription_package, :subscription_period,
               :subscription_discount, :preferred_delivery_slot, :unit_price, :order_id

    attribute :order, if: Proc.new { |rec,params| params[:order].present? }

    attribute :catalogue_variant do |object, params|
      if object.present?
        BxBlockCatalogue::CatalogueVariantSerializer.new(object.catalogue_variant, { params: params } ).serializable_hash[:data]
      end
    end

    attribute :product_name do |object|
      object&.catalogue&.name
    end

    attribute :product_price do |object|
      price = 0
      if object&.catalogue_variant_id.present?
        price = object.catalogue_variant&.on_sale? ? object.catalogue_variant&.sale_price : object.catalogue_variant&.price
      else
        price = object.catalogue&.on_sale? ? object.catalogue&.sale_price : object.catalogue&.price
      end
      price
    end

    attribute :item_total_price do |object|
      price = 0
      if object&.catalogue_variant_id.present?
        price = object.catalogue_variant&.on_sale? ? object.catalogue_variant&.sale_price : object.catalogue_variant&.price
      else
        price = object.catalogue&.on_sale? ? object.catalogue&.sale_price : object.catalogue&.price
      end
      price.to_f * object.quantity.to_i
    end

    attribute :product_sale_price do |object|
      object&.catalogue&.sale_price
    end

    attribute :product_on_sale do |object|
      object&.catalogue&.on_sale
    end

    attribute :product_stock_qty do |object|
      object&.catalogue&.stock_qty
    end

    attribute :review do |object|
      review = object.review
      {id:review&.id, comment:review&.comment, rating:review&.rating } if review.present?
    end

    attribute :product_images do |object, params|
      if object&.catalogue&.attachments&.present?
        BxBlockFileUpload::AttachmentSerializer.new(object&.catalogue&.attachments, { params: params })
      end
    end

    attribute :order_date do |object, params|
      object.order.order_date&.in_time_zone(Order::TIME_ZONE)&.strftime("%a, #{object.order.order_date&.day.ordinalize} %B %Y") if Proc.new { |rec,params| params[:order_date] }
    end

    attribute :order_number do |object, params|
      object.order.order_number if Proc.new { |rec,params| params[:order_number] }
    end

    attribute :delivery_address do |object|
      if object.order.delivery_address_orders.present?
        delivery_address_order = object.order.delivery_address_orders.joins(:delivery_address).where("delivery_addresses.address_for IN (?) ", ['shipping','billing_and_shipping']).last
        delivery_address_order&.delivery_address if delivery_address_order.present?
      end
    end
  end
end
