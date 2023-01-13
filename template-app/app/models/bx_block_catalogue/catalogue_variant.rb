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
  class CatalogueVariant < BxBlockCatalogue::ApplicationRecord
    self.table_name = :catalogue_variants

    # Associations
    belongs_to :catalogue, touch: true
    belongs_to  :tax, class_name: "BxBlockOrderManagement::Tax", optional: true

    has_many :variant_types
    has_many :order_items, class_name: "BxBlockOrderManagement::OrderItem", dependent: :destroy
    has_many :product_notifies, class_name: "BxBlockCatalogue::ProductNotify", dependent: :destroy
    has_many :catalogue_variant_properties, dependent: :destroy
    has_many :attachments, as: :attachable, class_name: "BxBlockFileUpload::Attachment"

    # has_many_attached :images, dependent: :destroy

    #Validations
    validates_presence_of :price, :stock_qty
    validates :price, numericality: { greater_than_or_equal_to: 1}
    validates :sale_price, numericality: { greater_than_or_equal_to: 1},
              if: Proc.new { |pv| pv.sale_price.present? }
    validates_presence_of :sale_price, if: Proc.new { |a| a.on_sale? }

    # Custom Validations
    validate :check_sale_price, :has_catalogue_variant_properties
    validate :has_images, on: :create, if: -> { self.catalogue.active? }
    validate :has_remained_any_image_on_update, on: :update, if: -> { self.catalogue.active? }
    validate :has_tax, if: -> { self.catalogue.active? }

    # ENUM Current availabilty
    enum current_availability: ['in_stock', 'out_of_stock']

    # Nested Attributes
    accepts_nested_attributes_for :catalogue_variant_properties, allow_destroy: true
    accepts_nested_attributes_for :attachments, allow_destroy: true
    accepts_nested_attributes_for :variant_types, allow_destroy: true

    # Callbacks
    after_destroy :update_default_variant
    before_save :calculate_tax_amount, :set_current_availablity
    after_save :set_default_variant, :set_product_price, :send_notification, :inventory_low_stock_mailings

    scope :first_available, -> { find_by('stock_qty > 0') }
    scope :first_available_default, -> { find_by('is_default = true AND stock_qty > 0') }

    def has_images
      errors.add(:base, 'must add at least one image') if self.attachments.blank?
    end

    def has_remained_any_image_on_update
      attachments_to_delete = self.attachments.select{|att| att._destroy == true}
      persisted_obj = BxBlockCatalogue::CatalogueVariant.find(self.id)
      remaining_attachments = persisted_obj.attachments.where.not(id: attachments_to_delete.pluck(:id))
      if remaining_attachments.count == 0
        errors.add(:base, 'must add at least one image') if self.attachments.blank? || self.attachments.any?{|att| att.cropped_image.blank?}
      end
    end

    def has_catalogue_variant_properties
      errors.add(:base, 'must add at least one variant property') if self.catalogue_variant_properties.blank?
    end

    def check_sale_price
      if self.sale_price.present? && (self.sale_price.to_f > self.price.to_f)
        errors.add(:sale_price, 'can not be greater then price')
      end
    end

    def available_stock_quantity
      self.stock_qty.to_i - self.block_qty.to_i
    end

    def set_default_variant
      if self.is_default?
        if self.stock_qty <= 0
          prod_variants = catalogue.catalogue_variants.where("stock_qty > ?", 0)
          if prod_variants.present?
            product_variant = prod_variants.first
            product_variant.update(is_default: true)
            product_variants = catalogue.catalogue_variants.where.not(id: product_variant.id)
            product_variants.update_all(is_default: false)
          end
        else
          product_variants = catalogue.catalogue_variants.where.not(id: self.id)
          product_variants.update_all(is_default: false)
        end
      else
        product_variants = catalogue.catalogue_variants.where(is_default: true)
        self.catalogue.catalogue_variants.first.update(is_default: true) if product_variants.blank?
      end
    end

    def update_default_variant
      product_variants = self.catalogue.catalogue_variants.where.not(id: self.id)
      if self.is_default? && product_variants.present?
        product_variants.first.update(is_default: true)
      end
    end

    def set_current_availablity
      available_in_stock = stock_qty.present? && self.available_stock_quantity >= 1
      self.current_availability = available_in_stock ? 'in_stock' : 'out_of_stock'
    end

    def set_product_price
      if self.is_default? && self.current_availability == "in_stock"
        self.catalogue.update(price: self.price, sale_price: self.sale_price, on_sale: self.on_sale, discount: self.discount_price, tax_amount: self.tax_amount, price_including_tax: self.price_including_tax, tax_id: self.tax_id)
      end
    end

    def send_notification
      if self.saved_change_to_current_availability? && self.in_stock? && self.product_notifies.present?
        user_ids = self.product_notifies.pluck(:account_id)
        message = "#{self&.catalogue&.name} is now available in stock."
        user_ids.each do |user_id|
          user = AccountBlock::Account.find_by(id: user_id)
          CatalogueVariantMailer.with(host: $hostname).product_stock_notification(self, user).deliver_now if user.present? && user.email.present?
          BxBlockNotification::SendNotification.new("", message, 'PRODUCT IS BACK', user , {catalogue_id: self&.catalogue&.id, notification_key: 'PRODUCT_IS_IN_STOCK'}).call if user.present? && user.email.present?
        end
        self.product_notifies.destroy_all
      end
    end

    def calculate_tax_amount
      tax = self.tax
      return unless tax.present?
      price = self.sale_price.present? ? self.sale_price : self.price
      # unless self.tax_included?
      tax_value = (price.to_f * 100) / (100 + tax.tax_percentage.to_f)
      tax_charge = price - tax_value
      self.tax_amount = tax_charge.round(2)
      self.price_including_tax = price.to_f.round(2)
      # else
      #   actual_price = ((price.to_f * 100) / (tax.tax_percentage.to_f + 100)).to_f.round(2)
      #   self.tax_amount = (price - actual_price).to_f.round(2)
      #   self.price_including_tax = price.to_f
      # end
    end

    private

    def has_tax
      errors.add(:base, 'must have a tax value') if self.tax.nil?
    end

    def inventory_low_stock_mailings
      if self.stock_qty.to_i <= 10
        AdminUser.all.each do |admin|
          CatalogueVariantMailer.with(host: $hostname).product_low_stock_notification(self, admin).deliver_now if admin.email.present?
        end
      end
    end
  end
end
