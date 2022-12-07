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
  class OrderItem < BxBlockOrderManagement::ApplicationRecord
    self.table_name = :order_items

    belongs_to :order
    belongs_to :catalogue, class_name: "BxBlockCatalogue::Catalogue"
    belongs_to :catalogue_variant, class_name: "BxBlockCatalogue::CatalogueVariant", optional: true

    belongs_to :order_status, optional: true

    has_one :review, :dependent => :destroy, class_name: "BxBlockCatalogue::Review"

    has_many :order_trackings, class_name: "OrderTracking", as: :parent
    has_many :trackings, through: :order_trackings
    has_many :subscription_orders, class_name: "BxBlockOrderManagement::SubscriptionOrder"

    scope :get_records, -> (ids){ where(order_id: ids) }
    scope :latest_first, -> { order('id DESC') }
    # validates_uniqueness_of :catalogue_variant_id, scope: [:catalogue_id, :order_id], on: :create

    validates :quantity, presence: true, unless: :subscription_quantity
    accepts_nested_attributes_for :subscription_orders


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

    end

    before_save :update_prices
    before_save :set_item_status,  if: :order_status_id_changed?
    after_save :update_product_stock, if: :order_status_id_changed?
    after_save :check_subscription_available

    def update_prices
      if from_catalogue_warehouse && self.order.order_date.blank?
        self.unit_price   = price if self.unit_price.blank?
        self.total_price  = order_item_total
      end
    end

    def set_item_status
      self.order_status_id = OrderStatus.find_or_create_by(status: self.status).id if (self.status.present?) && !(self.order_status.present?)
      event_name = order_status&.event_name
      unless order_status&.status == status
        begin
          self.send("#{event_name}!")
        rescue
          self.update_column(:status, 'event_name')
        end
      end
    end

    def update_product_stock
      product = self.catalogue_variant.present? ? self.catalogue_variant : self.catalogue
      if !self.manage_placed_status && self.order_status.present? && self.order_status.status == "placed"
        stock_qty = (product.stock_qty.to_i - self.quantity)
        block_qty = product.block_qty.to_i - self.quantity.to_i
        product.update!(stock_qty: stock_qty, block_qty: block_qty)
        if product.class.name == "CatalogueVariant"
          product.catalogue.update(stock_qty: product.catalogue.stock_qty - self.quantity, block_qty: product.catalogue.block_qty.to_i - self.quantity.to_i)
        end
        self.update(manage_placed_status: true)
      elsif !self.manage_cancelled_status && self.order_status.present? && self.order_status.status == "cancelled"
        # block_qty = product.block_qty.to_i - self.quantity.to_i
        product.update(stock_qty: product.stock_qty + self.quantity )
        if product.class.name == "CatalogueVariant"
          product.catalogue.update(stock_qty: product.catalogue.stock_qty + self.quantity)
        end
        self.update(manage_cancelled_status: true)
      end
    end

    def from_catalogue_warehouse
      self.catalogue_variant.present? ? self.catalogue_variant : self.catalogue
    end

    def price
      if self.catalogue_variant.present?
        catalogue_variant&.on_sale? ? catalogue_variant&.sale_price : catalogue_variant&.price
      else
        catalogue&.on_sale? ? catalogue&.sale_price : catalogue&.price
      end
    end

    def order_item_total
      if self.subscription_period.present? && subscription_package.present? && subscription_quantity.present?
        item_count = ((Date.tomorrow + subscription_period.to_i.months) - Date.tomorrow).to_i
        if self.subscription_package.to_s.downcase == 'daily'
          order_item_quantity = item_count * subscription_quantity
        elsif self.subscription_package.to_s.downcase == 'weekly'
          order_item_quantity = (item_count / 7 ) * subscription_quantity
        elsif self.subscription_package.to_s.downcase == 'monthly'
          order_item_quantity = subscription_period.to_i * subscription_quantity
        end
      else
        order_item_quantity = self.quantity
      end

      if self.subscription_discount.present? && self.subscription_discount.to_f > 0
        price = self.price.to_f - ((self.price.to_f * self.subscription_discount.to_f)/100) if self.subscription_discount.present? && self.price.present?
      end
      if price.present? && self.subscription_discount.present? && self.subscription_discount.to_f > 0
        (order_item_quantity.to_f * price.to_f)
      else
        (order_item_quantity.to_f * self.price.to_f)
      end
      # (order_item_quantity * self.price)
    end

    def update_state_process
      StateProcess.new(self, aasm).call
    end

    def tax_charge
      if has_subscription?
        tax_amount.to_f * order_item_qty.to_f
      else
        tax_amount.to_f * self.quantity
      end
    end

    def order_item_qty
      if has_subscription?
        item_count = ((Date.tomorrow + subscription_period.to_i.months) - Date.tomorrow).to_i
        if self.subscription_package.to_s.downcase == 'daily'
          order_item_quantity = item_count * subscription_quantity
        elsif self.subscription_package.to_s.downcase == 'weekly'
          order_item_quantity = (item_count / 7 ) * subscription_quantity
        elsif self.subscription_package.to_s.downcase == 'monthly'
          order_item_quantity = subscription_period.to_i * subscription_quantity
        end
        order_item_quantity
      else
        self.quantity.to_f
      end
    end

    def self.after_placed
      all.where(status:['placed', 'confirmed', 'in_transit', 'delivered', 'cancelled', 'refunded', 'returned'])
    end

    def total_item_quantity
      self.quantity || self.subscription_quantity
    end

    def check_subscription_available
      if subscription_quantity.present?
        self.order.update_column(:is_subscribed, true)
      end
    end

    def has_subscription?
      self.subscription_quantity.present? && self.subscription_period.present? && self.subscription_package.present?
    end

    def create_subscription_orders
      if has_subscription?
        item_count = ((Date.tomorrow + self.subscription_period.to_i.months) - Date.tomorrow).to_i
        if self.subscription_package.to_s.downcase == 'daily'
          (1..item_count).to_a.each do |day|
            delivery_date = Time.now + day.to_i.days
            self.subscription_orders.create(delivery_date: delivery_date, quantity: self.subscription_quantity)
          end
        elsif self.subscription_package.to_s.downcase == 'weekly'
          weekly_count = (item_count / 7 )
          (0..(weekly_count-1)).to_a.each do |week|
            delivery_date = Date.tomorrow + week.weeks
            self.subscription_orders.create(delivery_date: delivery_date, quantity: self.subscription_quantity)
          end
        elsif self.subscription_package.to_s.downcase == 'monthly'
          monthly_count = self.subscription_period.to_i
          (0..(monthly_count-1)).to_a.each do |month|
            delivery_date = Date.tomorrow + month.months
            self.subscription_orders.create(delivery_date: delivery_date, quantity: self.subscription_quantity)
          end
        end
      end
    end

    def cancel_subscription_orders
      if has_subscription?
        self.subscription_orders.update_all(status: 'cancelled')
      end
    end
  end
end
