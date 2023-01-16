# == Schema Information
#
# Table name: orders
#
#  id                      :bigint           not null, primary key
#  order_number            :string
#  amount                  :float
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  account_id              :bigint
#  coupon_code_id          :bigint
#  delivery_address_id     :bigint
#  sub_total               :decimal(, )      default(0.0)
#  total                   :decimal(, )      default(0.0)
#  status                  :string
#  applied_discount        :decimal(, )      default(0.0)
#  cancellation_reason     :text
#  order_date              :datetime
#  is_gift                 :boolean          default(FALSE)
#  placed_at               :datetime
#  confirmed_at            :datetime
#  in_transit_at           :datetime
#  delivered_at            :datetime
#  cancelled_at            :datetime
#  refunded_at             :datetime
#  source                  :string
#  shipment_id             :string
#  delivery_charges        :string
#  tracking_url            :string
#  schedule_time           :datetime
#  payment_failed_at       :datetime
#  returned_at             :datetime
#  tax_charges             :decimal(, )      default(0.0)
#  deliver_by              :integer
#  tracking_number         :string
#  is_error                :boolean          default(FALSE)
#  delivery_error_message  :string
#  payment_pending_at      :datetime
#  order_status_id         :integer
#  is_group                :boolean          default(TRUE)
#  is_availability_checked :boolean          default(FALSE)
#  shipping_charge         :decimal(, )
#  shipping_discount       :decimal(, )
#  shipping_net_amt        :decimal(, )
#  shipping_total          :decimal(, )
#  total_tax               :float
#
module BxBlockOrderManagement
  class Order < BxBlockOrderManagement::ApplicationRecord
    include UrlUtilities
    self.table_name = :orders
    attr_accessor :is_cancelled_by_user

    TIME_ZONE = ENV['COUNTRY_OF_STORE'].present? ? (ENV['COUNTRY_OF_STORE'].to_s.downcase == "india" ? "Asia/Kolkata" : "Europe/London") : "Asia/Kolkata"

    ORDER_NO_FORMAT = '00000000'

    ORDER_STATUS = %w(in_cart created placed confirmed in_transit delivered cancelled refunded payment_failed returned payment_pending)

    belongs_to :account, touch: true, class_name: "AccountBlock::Account"
    belongs_to :coupon_code, class_name: "BxBlockCouponCodeGenerator::CouponCode", optional: true

    belongs_to :order_status, optional: true

    has_one :review, class_name: "BxBlockCatalogue::Review"

    has_many :order_transactions, dependent: :destroy

    has_many :order_items, dependent: :destroy
    has_many :catalogues, class_name: "BxBlockCatalogue::Catalogue", through: :order_items

    has_many :order_trackings, class_name: "OrderTracking", as: :parent
    has_many :trackings, through: :order_trackings

    has_many :delivery_address_orders
    has_many :delivery_addresses, through: :delivery_address_orders

    validates :status, presence: true, inclusion: { in: BxBlockOrderManagement::OrderStatus.pluck(:status) }
    # validates :shipping_charge, :shipping_discount, :shipping_total, :shipping_net_amt, presence: true

    accepts_nested_attributes_for :order_items, allow_destroy: true
    accepts_nested_attributes_for :delivery_address_orders

    accepts_nested_attributes_for :delivery_addresses, :allow_destroy => true

    accepts_nested_attributes_for :order_transactions

    validates :order_items, presence: true, on: :create, if: -> { Rails.env != 'test' }

    scope :order_in_cart, -> { where(status: 'in_cart') }
    scope :not_in_cart, -> { where.not(status: ['in_cart','created']) }
    scope :total_sale_amount, -> { where(status: 'placed').map(&:total).compact.sum }
    scope :one_day_sale, -> { where(status: 'placed', placed_at: (Time.now - 24.hours)..Time.now).map(&:total).compact.sum }

    enum deliver_by: %i[fedex]
    before_update :set_status
    before_create :add_order_number
    around_update :check_order_date
    after_update :process_notification
    before_save :update_order_status, :update_ship_rocket_order_status, if: :order_status_id_changed?
    after_save :send_email_to_customer, if: :saved_change_to_order_status_id?
    after_save :update_product_stock, if: :saved_change_to_status?

    NOTIFICATION_KEYS = {
      PLACED: 'PLACED',
      CANCELLED: 'CANCELLED',
      CONFIRMED: 'CONFIRMED',
      DELIVERED: 'DELIVERED',
      IN_TRANSIT: 'IN TRANSIT'
    }

    include AASM
    aasm column: 'status' do
      state :in_cart, initial: true
      state :created,:placed, :confirmed, :in_transit, :delivered, :cancelled, :refunded, :payment_failed, :returned, :payment_pending

      event :in_cart do
        transitions  to: :in_cart
      end

      event :created do
        transitions  to: :created
      end

      event :pending_order do
        transitions from: %i[in_cart created payment_failed], to: :payment_pending, after: proc { |*_args| update_state_process }
      end

      event :place_order do
        transitions  to: :placed, after: proc { |*_args| update_state_process }
      end

      event :confirm_order do
        transitions to: :confirmed, after: proc{|*_args| update_state_process}
      end

      event :to_transit do
        transitions to: :in_transit, after: proc { |*_args| update_state_process }
      end

      event :payment_failed do
        transitions  to: :payment_failed, after: proc { |*_args| update_state_process }
      end

      event :deliver_order do
        transitions  to: :delivered, after: proc { |*_args| update_state_process }
      end

      event :cancel_order do
        transitions to: :cancelled, after: proc { |*_args| update_state_process }
      end

      event :refund_order do
        transitions  to: :refunded, after: proc { |*_args| update_state_process }
      end

      event :return_order do
        transitions to: :returned, after: proc { |*_args| update_state_process }
      end

      OrderStatus.new_statuses.each do |order_status|
        state order_status.status.to_s.downcase.to_sym
      end

    end

    EVENTS = %w[pending_order! place_order! confirm_order! to_transit! deliver_order! refund_order! cancel_order! payment_failed! return_order!]

    def update_state_process
      StateProcess.new(self, aasm).call
    end

    def set_status
      # check_holds
      if (OrderStatus::USER_STATUSES.include? self.status) && !(order_status_id_changed?)
        order_status = OrderStatus.find_or_create_by(status: self.status) if self.status.present?
        self.order_status_id = order_status.id unless self.order_status_id == order_status.id
      end
      self.order_items&.update(order_status_id: order_status_id) if (order_items.pluck(:order_status_id).uniq != [order_status_id]) && (is_group?)
    end

    def update_order_status
      self.status = order_status&.status if order_status&.status != status
    end

    def self.total_item_sold
      Order.includes(:order_items).not_in_cart.where('order_items.status NOT IN (?)',['in_cart','created']).references(:order_item).map{|order| order.order_items.pluck(:quantity)}.flatten.compact.sum
    end

    def total_price(is_release=false)
      if is_release == true
        order_items.sum(:total_price)&.round(2)
      else
        (order_items.sum(:total_price))&.round(2)
      end
    end

    def items_total
      price = 0
      total = 0
      self.order_items.each do |order_item|
        if order_item&.catalogue_variant_id.present?
          price = order_item.catalogue_variant&.on_sale? ? order_item.catalogue_variant&.sale_price : order_item.catalogue_variant&.price
        else
          price = order_item.catalogue&.on_sale? ? order_item.catalogue&.sale_price : order_item.catalogue&.price
        end
        total = total + (price.to_f * order_item.quantity.to_i)
      end
      total
    end

    def total_after_shipping_charge
      address = self.delivery_addresses.delivery_add.first
      zipcode = BxBlockZipcode::Zipcode.find_by_code(address&.zip_code)
      applied_shipping_charge = BxBlockShippingCharge::ShippingCharge.last
      if zipcode.present? && zipcode.activated
        charge = zipcode.charge
        self.shipping_charge = charge
        unless self.total <= zipcode.price_less_than
          self.shipping_discount = charge
        else
          self.shipping_discount = 0.0
        end
      else
        if applied_shipping_charge.present?
          default_charge = applied_shipping_charge.charge
          self.shipping_charge = default_charge
          unless self.total <= applied_shipping_charge.below
            self.shipping_discount = default_charge
          else
            self.shipping_discount = 0.0
          end
        else
          self.shipping_charge = 0.0
          self.shipping_discount = 0.0
        end
      end
      self.shipping_total = self.shipping_charge - self.shipping_discount
      self.shipping_net_amt = self.shipping_charge - self.shipping_discount
      self.total = self.total + self.shipping_total
    end

    # def total_after_tax_charge
    #   tax = Tax.last
    #   applied_tax = { tax_percentage: tax&.tax_percentage.to_f }
    #   if applied_tax.present?
    #     tax_charge = ((self.sub_total_price.to_f * applied_tax[:tax_percentage].to_f)/100).to_f.round(2)
    #     self.total_tax = tax_charge
    #     self.total = self.total.round(2) + self.total_tax.round(2)
    #   end
    # end

    def total_after_tax_charge
      total_tax_charge = self.order_items.map{|oi| get_tax(oi) }.compact.sum.to_f.round(2)
      self.total_tax = total_tax_charge
      tax_charge = self.order_items.map{|oi| get_tax(oi) }.compact.sum.to_f.round(2)
        #self.total = (self.total + tax_charge).round(2)
    end

    def get_tax(order_item)
      if order_item.subscription_quantity.present?
        order_item.catalogue.tax_amount.to_f * subscription_days_count(order_item)
      else
        order_item.catalogue_variant.present? ? order_item.catalogue_variant.tax_amount.to_f * order_item.quantity.to_f  : order_item.catalogue.tax_amount.to_f * order_item.quantity.to_f
      end
    end

    def subscription_days_count(order_item)
      if order_item.subscription_quantity.present?
        item_count = ((Date.tomorrow + order_item.subscription_period.to_i.months) - Date.tomorrow).to_i
        if order_item.subscription_package.to_s.downcase == 'daily'
          order_item_quantity = item_count * order_item.subscription_quantity
        elsif order_item.subscription_package.to_s.downcase == 'weekly'
          order_item_quantity = (item_count / 7 ) * order_item.subscription_quantity
        elsif order_item.subscription_package.to_s.downcase == 'monthly'
          order_item_quantity = order_item.subscription_period.to_i * order_item.subscription_quantity
        end
      else
        nil
      end
    end

    def sub_total_price
      order_items.sum(:total_price)&.round(2)
    end

    def full_order_cancelled?
      self.order_items.cancelled.count == self.order_items.count
    end

    def add_order_number
      self.order_number = 'OD' + Order.next_order_number
    end

    def self.next_order_number
      return Order::ORDER_NO_FORMAT.succ if Order.count.nil?
      (Order.count&.positive? ? Order.last&.order_number&.split('OD')[1] : Order::ORDER_NO_FORMAT).succ
    end

    def latest_payment
      self.order_transactions.order(:created_at).last
    end

    def shipping_charge_details
      {shipping_charge:shipping_charge.to_i, shipping_discount:shipping_discount.to_i, shipping_net_amt:shipping_net_amt.to_i, shipping_total:shipping_total.to_i}
    end

    def self.total_cart_item(account)
      cart_item = account.orders.where(status: 'in_cart')&.last&.order_items
      cart_item&.length || 0
    end

    def self.after_placed
      all.where(status:['placed', 'confirmed', 'in_transit', 'delivered', 'cancelled', 'refunded', 'returned'])
    end

    def process_notification
      return unless self.account&.is_notification_enabled
      if self.placed?
        create_notification('Order placed', NOTIFICATION_KEYS[:PLACED])
      elsif self.cancelled?
        create_notification('Order cancellation', NOTIFICATION_KEYS[:CANCELLED])
      elsif self.delivered?
        create_notification('Order delivered', NOTIFICATION_KEYS[:DELIVERED])
      elsif self.in_transit?
        create_notification('Order in transit', NOTIFICATION_KEYS[:IN_TRANSIT])
      elsif self.confirmed?
        create_notification('Order confirmed', NOTIFICATION_KEYS[:CONFIRMED])
      end
    end

    def send_email_to_customer
      return unless self.account&.is_notification_enabled
      return unless self.account&.is_email_valid?
      OrderMailer.with(host: $hostname).order_status_notification(self).deliver_now if self.saved_change_to_order_status_id? && !['in_cart', 'created', 'confirmed', 'placed'].include?(self.status)
      if self.placed?
        OrderMailer.with(host: $hostname).order_placed(self).deliver_later(wait: 10.seconds)
        OrderMailer.with(host: $hostname).admin_order_placed(self).deliver_later(wait: 10.seconds)
      elsif self.confirmed?
        OrderMailer.with(host: $hostname).order_confirmed(self).deliver_now
      end
    end

    def create_notification(title, message)
      BxBlockNotification::Notification.find_or_create_by( source_id: self.id, source: 'Order', title: title, message: message, account_id: self.account&.id )
    end

    def update_product_stock
      Rails.logger.error ">>>>>>>>>>>>>>>>>Product Stock #{self.is_availability_checked?} #{self.is_blocked?} #{self.id}>>>>>>>>>>>>"
      if self.is_availability_checked? && self.is_blocked?
        order_items = self.order_items
        order_items.each do |order_item|
          quantity = order_item.quantity.to_i
          subscription_quantity = order_item.subscription_quantity.to_i
          product = order_item.catalogue_variant.present? ? order_item.catalogue_variant : order_item.catalogue
          Rails.logger.error ">>>>>>>>>>>>>>>>>Order Placed Model: #{self.placed?}>>>>>>>>>>>>"
          if self.placed?
            product.with_lock do
              if product.class.name == "BxBlockCatalogue::CatalogueVariant"
                product.update_columns(stock_qty: (product.stock_qty.to_i - quantity),
                                block_qty: product.block_qty.to_i - quantity.to_i)
                product.catalogue.update_columns(stock_qty: product.catalogue.stock_qty - quantity, block_qty: product.catalogue.block_qty.to_i - quantity.to_i, sold: (product.catalogue.sold.to_i + quantity))
              elsif product.class.name == "BxBlockCatalogue::Catalogue"
                product.update_columns(stock_qty: (product.stock_qty.to_i - quantity - subscription_quantity.to_i),
                                block_qty: product.block_qty.to_i - quantity.to_i - subscription_quantity.to_i, sold: (product.sold.to_i + quantity + subscription_quantity)
                )
              end
            end
            order_item.create_subscription_orders
          elsif self.cancelled?
            product.with_lock do
              product.update_column('stock_qty', product.stock_qty + quantity )
              if product.class.name == "BxBlockCatalogue::CatalogueVariant"
                product.catalogue.update_column('stock_qty', product.catalogue.stock_qty + quantity)
              end
            end
            order_item.cancel_subscription_orders
          end
        end
      elsif !self.is_blocked? && self.is_availability_checked?
        order_status_id = OrderStatus.find_by(status:"cancelled").id
        self.is_cancelled_by_user = false
        self.update_column(:order_status_id, order_status_id)
        self.update_column(:status, 'cancelled')
        message = "Hi #{self.account&.full_name}, We have cancelled your order due to request time out. A refund of ₹ #{self.sub_total}  will be initiated to your Card / Bank account."
        create_notification('Order Cancelled', message)
      end
    end

    def update_shipment_details(json_response)
      if json_response['status'].to_s.downcase == 'new'
        order_status_id = OrderStatus.find_by(status:"confirmed").id
      end
      self.update(logistics_ship_rocket_enabled: true, ship_rocket_order_id: json_response['order_id'], ship_rocket_shipment_id: json_response['shipment_id'], ship_rocket_status: json_response['status'].to_s.downcase, ship_rocket_status_code: json_response['status_code'], ship_rocket_onboarding_completed_now: json_response['onboarding_completed_now'], ship_rocket_awb_code: json_response['awb_code'], ship_rocket_courier_company_id: json_response['courier_company_id'], ship_rocket_courier_name: json_response['courier_name'], order_status_id: order_status_id.present? ? order_status_id : self.order_status_id )
    end

    def update_ship_rocket_order_status
      if self.cancelled? && self.logistics_ship_rocket_enabled && self.ship_rocket_order_id.present?
        ship_rocket = BxBlockOrderManagement::ShipRocket.new
        ship_rocket.authorize
        ship_rocket.cancel_order(self.id)
        if self.ship_rocket_status == 'new'
          self.update(ship_rocket_status: 'cancelled')
          if self.order_items.present?
            self.order_items.each do |order_item|
              tracking = BxBlockOrderManagement::Tracking.find_or_create_by(date: DateTime.current, status: "cancelled" )
              order_item.order_trackings.create(tracking_id: tracking.id)
            end
          end
        end
      end
    end

    def change_email_keywords(content, order_items_content)
      delivery_addresses = self.delivery_addresses
      if delivery_addresses.first&.address_for.to_s.downcase == 'billing_and_shipping'
        billing_address = delivery_addresses.first
        shipping_address = delivery_addresses.first
      else
        billing_address = delivery_addresses.where(address_for: 'billing').first
        shipping_address = delivery_addresses.where(address_for: 'shipping').first
      end
      BxBlockSettings::EmailSetting::ORDER_EMAIL_KEYWORDS.each do |key|
        default_email_setting = BxBlockSettings::DefaultEmailSetting.first
        case  key
        when 'order_id'
          content = content.gsub!("%{#{key}}", self.order_number ) || content
        when 'customer_name'
          content = content.gsub!("%{#{key}}", self.account&.full_name.to_s ) || content
        when 'billing_address'
          content = content.gsub!("%{#{key}}", billing_address&.address.to_s ) || content
        when 'shipping_address'
          content = content.gsub!("%{#{key}}", shipping_address&.address.to_s) || content
        when 'order_status'
          content = content.gsub!("%{#{key}}", self&.status) || content
        when 'order_summary'
          content = content.gsub!("%{#{key}}", order_items_content ) || content
        when 'order_tracking'
          content = content.gsub!("%{#{key}}", self.trackings.last&.status.to_s) || content
        when 'brand_name'
          content = content.gsub!("%{#{key}}", default_email_setting&.brand_name.to_s ) || content
        when 'brand_logo'
          content = content.gsub!("%{#{key}}", "<div><img width='20%' src='#{url_for(default_email_setting.logo)}'/></div>" ) || content
        when 'recipient_email'
          content = content.gsub!("%{#{key}}", default_email_setting&.contact_us_email_copy_to.to_s ) || content
        end
      end
      content
    end

    private

    def check_order_date
      self.order_date = nil if self.status == 'in_cart' || self.status == 'created'
      yield
    end
  end
end
