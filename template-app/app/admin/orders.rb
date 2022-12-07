module Orders
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

unless Orders::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockOrderManagement::Order, as: "Orders" do
    menu :label => "<i class='fa fa-list gray-icon'></i> Orders".html_safe, priority: 3
    total_amount = 0
    actions :all, except: %i[destroy show new]

    permit_params :order_number, :amount, :account_id, :coupon_code_id, :delivery_address_id, :sub_total, :total, :status, :length, :breadth, :height, :weight,
                  :applied_discount, :cancellation_reason, :order_date, :is_gift, :placed_at, :confirmed_at, :in_transit_at,
                  :delivered_at, :cancelled_at, :refunded_at, :source, :shipment_id, :delivery_charges, :tracking_url,
                  :schedule_time, :payment_failed_at, :returned_at, :tax_charges, :deliver_by, :tracking_number, :is_error,
                  :delivery_error_message, :payment_pending_at, :order_status_id, :is_group, :is_availability_checked,
                  :shipping_charge, :shipping_discount, :shipping_net_amt, :shipping_total, :total_tax, :razorpay_order_id,
                  order_items_attributes: [:catalogue_id, :order_status, :order_status_id, :quantity, :unit_price, :total_price, :_destroy, :id, subscription_orders_attributes: [:order_item_id, :id, :status, :_destroy]],
                  delivery_addresses_attributes: [:id, :account_id, :name, :flat_no, :address, :zip_code, :phone_number, :address_for, :city, :state, :country, :_destroy],
                  order_transactions_attributes: [:id, :charge, :amount, :currency, :charge_status, :status, :payment_provider, :razorpay_order_id, :payment_id]

    scope :all

    action_item :order_statuses do
      link_to 'Order Status', admin_order_statuses_path
    end


    action_item :order_report, only: :index do
      link_to 'Order Report', admin_order_report_path
    end

    BxBlockOrderManagement::Order.where.not(status: ['in_cart','created']).order(:status).pluck(:status).uniq.each do |status|
      scope status.humanize, default: status.casecmp('all').zero? do |orders|
        orders.where(status: status)
      end
    end

    filter :order_date
    filter :total

    #Razorpay refund
    member_action :refund_razorpay, method: :post do
      if resource.order_transactions.last.payment_id
        payment_id = resource.order_transactions.last.payment_id
        payment = Razorpay::Payment.fetch(payment_id)
        payment.refund
        redirect_to resource_path, notice: 'Refund done successfully for this order'
      else
        redirect_to resource_path, notice: 'Payment is not succeed for this order'
      end
    end

    member_action :cancel, method: :post do
      resource.update!(cancellation_reason: params[:cancellation_reason])
      resource.cancel_order
      flash[:notice] =  t('messages.success.cancelled', resource: resource.class.name)
    end

    member_action :ship_by_ship_rocket, method: :get do
      if resource.height.blank? || resource.length.blank? || resource.breadth.blank? || resource.weight.blank?
        redirect_to request.referer, alert: 'Before send to ShipRocket you must be filled height, breadth, length and weight for this order.' and return
      end
      ship_rocket = BxBlockOrderManagement::ShipRocket.new
      if ship_rocket.authorize
        response = ship_rocket.post_order(resource.id)
        json_response = JSON.parse(response.body)
        if json_response['errors'].present?
          redirect_to request.referer, alert: json_response['errors'].values.flatten.join(',')
        else
          resource.update_shipment_details(json_response)
          if resource.order_items.present?
            resource.order_items.each do |order_item|
              tracking = BxBlockOrderManagement::Tracking.find_or_create_by(date: DateTime.current, status: json_response['status'].to_s.downcase )
              order_item.order_trackings.create(tracking_id: tracking.id)
            end
          end
          redirect_to request.referer, notice: 'Shipping request has been sent to ShipRocket successfully.'
        end
      else
        redirect_to request.referer, notice: 'Something went wrong, while shiping with Ship Rocket'
      end
    end

    member_action :group, method: :put do
      unless resource.is_group
        resource.update(is_group:true)
      else
        resource.update(is_group:false)
      end
      redirect_to request.referer
    end

    member_action :download_invoice, method: :get do
      @order = BxBlockOrderManagement::Order.find(params[:id])
      delivery_addresses = @order.delivery_address_orders
      @shipping_address = delivery_addresses.where(address_for: 'shipping').last&.delivery_address
      @shipping_address = delivery_addresses.where(address_for: 'billing_and_shipping').last&.delivery_address if @shipping_address.blank?
      @billing_address = delivery_addresses.where(address_for: 'billing').present? ? delivery_addresses.where(address_for: 'billing').last&.delivery_address : delivery_addresses.where(address_for: 'billing_and_shipping').last&.delivery_address
      respond_to do |format|
        format.pdf do
          render pdf: "#{@order.order_number}.pdf", disposition: 'attachment', template: 'admin/csv/download_invoice.html.erb'
        end
      end
    end

    action_item :ship_by_ship_rocket, if: proc { action_name == 'edit' && BxBlockStoreProfile::BrandSetting.first.country == "india" } do
      if resource.logistics_ship_rocket_enabled
        'Shiped by ShipRocket'
      else
        link_to 'Ship by ShipRocket', action: 'ship_by_ship_rocket'
      end
    end

    form do |f|
      f.semantic_errors
      if f.object.new_record?
        f.render partial: 'order_form', handlers: [:haml], locals: { f: f, admin_user: current_admin_user }
      else
        f.inputs 'Order Details' do
          f.input :id, input_html: { disabled: true }
          f.input :order_number, input_html: { disabled: true }
          f.input :order_date, as: :datepicker, input_html: { disabled: true }
          f.input :account_id, input_html: { disabled: true, data: { user_id: f.object.account_id } }
          # f.input :status, collection: BxBlockOrderManagement::Order::ORDER_STATUS
          f.input :order_status, collection: BxBlockOrderManagement::OrderStatus.admin_panel_statuses.where(active:true).map { |u| [u&.name, u&.id] }, include_blank: true, input_html: { disabled: f.object.logistics_ship_rocket_enabled }
          f.input :sub_total, input_html: { disabled: true }
          f.input :total, input_html: { disabled: true }
          f.input :coupon_code_id, input_html: { disabled: true, data: { user_id: f.object.coupon_code_id } }
          f.input :applied_discount, input_html: { disabled: true }
          f.input :is_gift
        end

        columns do
          column do
            f.inputs 'Order Items' do
              # f.has_many :order_items, heading: false, allow_destroy: true, new_record: 'Add New Order Items' do |oi|
              f.has_many :order_items, heading: false, new_record: false do |oi|
                oi.input :catalogue, input_html: { disabled: true } #, collection: BxBlockCatalogue::Catalogue.active.map { |u| [u&.name, u.id] }, include_blank: false, input_html: { class: 'select2' }
                oi.input :order_status, collection:  oi.object.order&.is_group ? BxBlockOrderManagement::OrderStatus.admin_panel_statuses.where(active:true).map { |u| [u&.name, u&.id] } : BxBlockOrderManagement::OrderStatus.admin_panel_statuses.where(active:true).map { |u| [u&.name, u&.id] }, input_html: oi.object.order&.is_group ? {disabled:true} : {disabled:false}, include_blank: true
                if oi.object.quantity.present?
                  oi.input :quantity, input_html: {disabled: true }
                else
                  oi.input :subscription_quantity, input_html: { class: 'item_quantity', disabled: true }
                  oi.input :subscription_package, input_html: { class: 'item_quantity', disabled: true }
                  oi.input :subscription_period, input_html: { class: 'item_quantity', disabled: true, value: "#{oi.object.subscription_period} Month" }
                end
                # if oi.object.delivered? || oi.object.order&.delivered?
                #   oi.input :quantity, input_html: { readonly: true }
                # else
                #   oi.input :quantity
                # end
                oi.object.catalogue_variant&.catalogue_variant_properties&.each do |property|
                  oi.input BxBlockCatalogue::Variant.find(property.variant_id).name, input_html: { value: BxBlockCatalogue::VariantProperty.find(property.variant_property_id).name, readonly: true }
                end
                oi.input :unit_price, input_html: { disabled: true }
                oi.input :total_price, input_html: { disabled: true }
                if oi.object.subscription_orders.present?
                  oi.has_many :subscription_orders, heading: 'Subscription Order Detail', allow_destroy: false, new_record: false do |so|
                    so.input :delivery_date,  as: :datepicker, input_html: {value: so.object.delivery_date.strftime("%d-%m-%Y") , disabled: true}
                    so.input :quantity, input_html: {disabled: true}
                    so.input :status, collection: ['pending','delivered','cancelled'], selected: so.object.status , input_html: {disabled: (so.object.delivery_date < Date.today || so.object.cancelled? || so.object.delivered? ) }
                  end
                end
              end
            end
          end

          column do
            f.inputs 'Delivery Address' do
              f.has_many :delivery_addresses, heading: false, allow_destroy: true do |da|
                da.input :account_id, as: :hidden, input_html: {value: f.object.account_id}
                da.input :name
                da.input :flat_no
                da.input :address
                da.input :zip_code
                da.input :phone_number
                da.input :address_for
                da.input :city
                da.input :state
                da.input :country
              end
            end
          end
        end

        columns do
          column do
            f.inputs 'Transaction Details' do
              f.has_many :order_transactions, heading: false, new_record: false do |ot|
                ot.object.amount = ot.object.amount.to_s.to_f > 0 ? (ot.object.amount.to_f / 100) : "0".to_f if ot.object.present?
                ot.input :charge_id, input_html: { disabled: true }
                ot.input :amount, input_html: { disabled: true }
                ot.input :currency, input_html: { disabled: true }
                ot.input :charge_status, input_html: { disabled: true }
                ot.input :status, input_html: { disabled: true }
                ot.input :payment_provider, input_html: { disabled: true }
                ot.input :razorpay_order_id, input_html: { disabled: true }
                ot.input :payment_id, input_html: { disabled: true }
              end
            end
          end
        end

        columns do
          column do
            f.inputs  'Review and Ratings', for: [:review, object.review] do |rev|
              rev.input :rating, input_html: {disabled: true}
              rev.input :comment, input_html: {disabled: true}
            end
          end
        end

        f.inputs 'Packaging Details' do
          f.input :height, label: 'Height in cms(more than 0.5)'
          f.input :breadth, label: 'Breadth in cms(more than 0.5)'
          f.input :length, label: 'Length in cms(more than 0.5)'
          f.input :weight, label: 'Weight in kgs(more than 0)'
        end

        columns do
          column do
            f.actions
          end
        end
      end
    end

    index do
      column :id
      column :order_number
      column :order_date
      column 'Customer', sortable: 'account.first_name', &:account
      state_column :status do |order|
        order&.status&.titleize
      end

      column 'Total With Tax', sortable: :total do |order|
        order.total.round(2)
      end
      actions defaults: false do |order|
        link_to 'Invoice', download_invoice_admin_order_path(order, format: :pdf), class: 'view_link member_link'
      end
      actions
      div class: "panel" do
        h3 "Total amount: #{collection.pluck(:total).compact.reduce(:+)&.round(2)}"
      end
    end

    controller do
      def scoped_collection
        BxBlockOrderManagement::Order.includes(:account, :coupon_code, order_items: :catalogue).where.not(status: ['in_cart','created'])
      end

      def create
        params[:order][:delivery_addresses_attributes]['0'][:account_id] = params[:order][:account_id]
        super do
          if resource.valid?
            resource.place_order!
            flash[:notice] = t('messages.success.created', resource: 'Order')
            redirect_to admin_orders_url and return
          end
        end
      end

      def update
        super do
          if resource.valid?
            order_params = params[:order]
            unless  order_params[:order_status_id].to_s == resource.order_status_id.to_s
              order_status = BxBlockOrderManagement::OrderStatus.find(params[:order][:order_status_id]) if params[:order][:order_status_id].present?

              event_name = order_status&.event_name if order_status.present?
              if BxBlockOrderManagement::Order::EVENTS.include? "#{event_name}!"
                resource.send("#{event_name}!")  unless resource.order_status.event_name == event_name
              end
            end
          else
            flash[:error]= "Somethong is wrong."
          end
          resource.order_items.update(order_status_id: order_params[:order_status_id]) if resource.is_group? && resource.order_items.pluck(:order_status_id).uniq != [resource.order_status_id]

          flash[:notice] = t('messages.success.updated', resource: 'Order')
          redirect_to edit_admin_order_path(resource) and return
        end
      end
    end

    after_save do |order|
      @cart_response = BxBlockOrderManagement::UpdateCartValue.new(order, order.account).call
    end
  end
end
