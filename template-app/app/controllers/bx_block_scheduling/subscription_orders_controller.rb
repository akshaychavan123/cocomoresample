module BxBlockScheduling
  class SubscriptionOrdersController < ApplicationController
    def get_subscription_orders
      order_item = BxBlockOrderManagement::OrderItem.find(params[:order_item_id])
      sub_orders = order_item.subscription_orders
      if sub_orders.present? && params[:per_page].present?
        mod = sub_orders.count % params[:per_page].to_i
        pages = sub_orders.count / params[:per_page].to_i
        pages += 1 if mod > 0
      else
        pages = 0
      end
      count = sub_orders.length
      page_no = params[:page].to_i == 0 ? BxBlockOrderManagement::SubscriptionOrder::PAGE : params[:page].to_i
      per_page = params[:per_page].to_i == 0 ? BxBlockOrderManagement::SubscriptionOrder::PER_PAGE : params[:per_page].to_i
      sub_orders = sub_orders.page(page_no).per(per_page)

      render json: {
        success: true,
        data: BxBlockOrderManagement::SubscriptionOrdersSerializer.new(sub_orders).serializable_hash[:data],
        meta: {
          pagination: {
            current_page: sub_orders.current_page,
            next_page: sub_orders.next_page,
            prev_page: sub_orders.prev_page,
            total_pages: pages.present? ? pages : '',
            total_count: count
          }
        }
      }
    end

    def extend_delivery
      subscription_order = BxBlockOrderManagement::SubscriptionOrder.find(params[:id])
      if subscription_order.update(status: 'cancelled')
        render json: {
          success: true,
          data:
            BxBlockOrderManagement::SubscriptionOrdersSerializer.new(subscription_order).serializable_hash[:data]
        }
      else
        render json: {
          success: false,
          errors: [{subscription_order: subscription_order.errors.full_messages.to_sentence}]
        },
               status: 422
      end
    end
  end
end
