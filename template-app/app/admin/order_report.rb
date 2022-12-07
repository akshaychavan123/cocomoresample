# frozen_string_literal: true

module OrderReport
  class Load
    @@loaded_from_gem = false
    def self.is_loaded_from_gem
      @@loaded_from_gem
    end

    def self.loaded
    end

    # Check if this file is loaded from gem directory or not
    # The gem directory looks like
    # /template-app/.gems/gems/studio_store_ecommerce_[block_name]-0.0.[version]/app/admin/[admin_template].rb
    # if it has block's name in it then it's a gem
    @@loaded_from_gem = Load.method('loaded').source_location.first.include?('studio_store_ecommerce_')
  end

end

unless OrderReport::Load.is_loaded_from_gem
  ActiveAdmin.register_page 'Order Report' do
    menu false
    sidebar :filter unless config.sidebar_sections.map(&:name).include?("filter")
    content title: proc { I18n.t('active_admin.order_report') } do

      orders = BxBlockOrderManagement::Order.not_in_cart.where('extract(month from order_date) = ?',Date.today.month ) unless params[:order_report].present?

      orders = BxBlockOrderManagement::Order.not_in_cart.where(order_date:params[:order_report][:from]&.to_date&.beginning_of_day..params[:order_report][:to]&.to_date&.end_of_day) if params[:order_report].present?

      orders_sum = 0

      sale_items_sum = 0

      sales_total_sum = 0

      invoiced_sum = 0

      refunded_sum = 0

      sales_tax_sum = 0

      sales_shipping_sum = 0

      sales_discount_sum = 0

      cancelled_sum = 0

      columns do
        column do
          panel "Order Report" do
            dates = orders.pluck(:order_date).compact
            utc_dates = dates.map{|date|date.in_time_zone('UTC')}
            utc_dates.compact.map{|a|a.to_date}.uniq.sort.reverse.each do |date|

              get_orders = BxBlockOrderManagement::Order.not_in_cart.where(order_date:date.in_time_zone('UTC').beginning_of_day..date.in_time_zone('UTC').end_of_day)
              orders_count = get_orders&.count

              sale_items = BxBlockOrderManagement::OrderItem.where(order_id:get_orders.pluck(:id)).after_placed&.sum(&:total_item_quantity)


              sales_total = BxBlockOrderManagement::Order.after_placed.where(order_date:date.in_time_zone('UTC').beginning_of_day..date.in_time_zone('UTC').end_of_day)&.sum(:total).to_f.round(2)

              invoiced = BxBlockOrderManagement::Order.not_in_cart.where(order_date:date.in_time_zone('UTC').beginning_of_day..date.in_time_zone('UTC').end_of_day).where(status:"delivered")&.sum(:total).to_f.round(2)

              refunded = BxBlockOrderManagement::Order.where(order_date:date.in_time_zone('UTC').beginning_of_day..date.in_time_zone('UTC').end_of_day).where(status:"refunded")&.sum(:total).to_f.round(2)

              sales_tax = BxBlockOrderManagement::Order.after_placed.where(order_date:date.in_time_zone('UTC').beginning_of_day..date.in_time_zone('UTC').end_of_day)&.sum(:total_tax).to_f.round(2)

              sales_shipping = BxBlockOrderManagement::Order.after_placed.where(order_date:date.in_time_zone('UTC').beginning_of_day..date.in_time_zone('UTC').end_of_day)&.sum(:shipping_total).to_f.round(2)

              sales_discount = BxBlockOrderManagement::Order.after_placed.where(order_date:date.in_time_zone('UTC').beginning_of_day..date.in_time_zone('UTC').end_of_day)&.sum(:applied_discount).to_f.round(2)

              cancelled = BxBlockOrderManagement::Order.where(order_date:date.in_time_zone('UTC').beginning_of_day..date.in_time_zone('UTC').end_of_day).where(status:"cancelled")&.sum(:total).to_f.round(2)

              orders_sum = orders_count + orders_sum
              sale_items_sum = sale_items + sale_items_sum
              sales_total_sum = sales_total + sales_total_sum
              invoiced_sum = invoiced + invoiced_sum
              refunded_sum = refunded + refunded_sum
              sales_tax_sum = sales_tax + sales_tax_sum
              sales_shipping_sum = sales_shipping + sales_shipping_sum
              sales_discount_sum = sales_discount + sales_discount_sum
              cancelled_sum = cancelled + cancelled_sum
            end
            # table_for dates.map{|a|a.to_date}.uniq.each do |date|
            # dates.map{|a|a.to_date}.uniq.each do |date|
            table_for dates.compact.map{|a|a.to_date}.uniq.sort.reverse do |date|
              column (:period) {|date| date.to_date.strftime('%b %d, %Y')}
              column (:orders){|date| BxBlockOrderManagement::Order.not_in_cart.where(order_date:date.in_time_zone('UTC').beginning_of_day..date.in_time_zone('UTC').end_of_day).count }
              column (:sale_items) {|date| BxBlockOrderManagement::OrderItem.where(order_id:BxBlockOrderManagement::Order.not_in_cart.where(order_date:date.in_time_zone('UTC').beginning_of_day..date.in_time_zone('UTC').end_of_day).pluck(:id)).after_placed&.sum(&:total_item_quantity)}
              column (:sales_total) {|date| "₹#{BxBlockOrderManagement::Order.after_placed.where(order_date:date.in_time_zone('UTC').beginning_of_day..date.in_time_zone('UTC').end_of_day)&.sum(:total).to_f.round(2)}"}
              column (:invoiced){|date| "₹#{BxBlockOrderManagement::Order.where(order_date:date.in_time_zone('UTC').beginning_of_day..date.in_time_zone('UTC').end_of_day).where(status:"delivered")&.sum(:total).to_f.round(2)}" }
              column (:refunded){|date| "₹#{BxBlockOrderManagement::Order.where(order_date:date.in_time_zone('UTC').beginning_of_day..date.in_time_zone('UTC').end_of_day).where(status:"refunded")&.sum(:total).to_f.round(2)}" }
              column (:sales_tax){|date| "₹#{BxBlockOrderManagement::Order.after_placed.where(order_date:date.in_time_zone('UTC').beginning_of_day..date.in_time_zone('UTC').end_of_day)&.sum(:total_tax).to_f.round(2)}" }
              column (:sales_shipping){|date| "₹#{BxBlockOrderManagement::Order.after_placed.where(order_date:date.in_time_zone('UTC').beginning_of_day..date.in_time_zone('UTC').end_of_day)&.sum(:shipping_total).to_f.round(2)}"}
              column (:sales_discount){|date| "₹#{BxBlockOrderManagement::Order.after_placed.where(order_date:date.in_time_zone('UTC').beginning_of_day..date.in_time_zone('UTC').end_of_day)&.sum(:applied_discount).to_f.round(2)}" }
              column (:cancelled){|date| "₹#{BxBlockOrderManagement::Order.where(order_date:date.in_time_zone('UTC').beginning_of_day..date.in_time_zone('UTC').end_of_day).where(status:"cancelled")&.sum(:total).to_f.round(2)}" }
              # end
            end
          end
        end
      end

      columns do
        column do
          panel "Total" do
            table_for "Total" do
              column (:orders_sum) {|order| orders_sum }
              column (:sale_items_sum) {|order| sale_items_sum }
              column (:sales_total_sum) {|order| "₹#{sales_total_sum.to_f.round(2)}" }
              column (:invoiced_sum) {|order| "₹#{invoiced_sum.to_f.round(2)}" }
              column (:refunded_sum) {|order| "₹#{refunded_sum.to_f.round(2)}" }
              column (:sales_tax_sum) {|order| "₹#{sales_tax_sum.to_f.round(2)}" }
              column (:sales_shipping_sum) {|order| "₹#{sales_shipping_sum.to_f.round(2)}" }
              column (:sales_discount_sum) {|order| "₹#{sales_discount_sum.to_f.round(2)}" }
              column (:cancelled_sum) {|order| "₹#{cancelled_sum.to_f.round(2)}" }
            end
          end
        end
      end
      columns do
        column span: 2 do
          number_with_delimiter(orders.count, :delimiter => ',')
          #link_to "Download CSV Report", bx_block_order_management_export_csv_path(order_ids: orders.pluck(:id))
        end
      end
    end
  end
end
