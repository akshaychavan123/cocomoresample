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
module BxBlockCatalogue
  class Catalogue < BxBlockCatalogue::ApplicationRecord
    attr_accessor :cart_quantity
    # attr_accessor :cropped_image

    PAGE = 1
    PER_PAGE = 10
    ATTACHMENT_SIZE = { min_width: 374, max_width: 400, min_height: 400, max_height: 800 }

    self.table_name = :catalogues

    enum availability: %i[in_stock out_of_stock]
    enum status: %i[active draft]

    # Associations
    belongs_to :brand, optional: true
    belongs_to  :tax, class_name: "BxBlockOrderManagement::Tax", optional: true

    has_and_belongs_to_many :sub_categories,
                            class_name: 'BxBlockCategoriesSubCategories::SubCategory',
                            join_table: 'catalogues_sub_categories', foreign_key: 'catalogue_id'
    has_many :order_items, class_name: "BxBlockOrderManagement::OrderItem", dependent: :destroy
    has_many :orders,
             class_name: "BxBlockOrderManagement::Order", through: :order_items, dependent: :destroy

    has_many :reviews, dependent: :destroy
    has_many :catalogue_variants,
             class_name: "BxBlockCatalogue::CatalogueVariant", dependent: :destroy
    has_many :product_notifies, class_name: "BxBlockCatalogue::ProductNotify", dependent: :destroy
    has_and_belongs_to_many :tags, join_table: :catalogues_tags
    has_and_belongs_to_many :bulk_images, class_name: 'BxBlockCatalogue::BulkImage',
      join_table: 'catalogues_bulk_images', optional: true

    # has_many_attached :images, dependent: :destroy
    has_many :attachments, as: :attachable, class_name: "BxBlockFileUpload::Attachment", dependent: :destroy
    has_many    :catalogue_subscriptions, dependent: :destroy

    # Nested attributes
    accepts_nested_attributes_for :catalogue_subscriptions, allow_destroy: true
    accepts_nested_attributes_for :attachments, allow_destroy: true, reject_if: :all_blank
    accepts_nested_attributes_for :catalogue_variants, allow_destroy: true, reject_if: :all_blank
    accepts_nested_attributes_for :catalogue_variants, allow_destroy: true
    accepts_nested_attributes_for :tags

    # Validations
    validates :name, :price, :stock_qty, presence: true
    validates_uniqueness_of :sku, :allow_blank => true
    validates_presence_of :sale_price, if: Proc.new { |a| a.on_sale? }
    # validate :has_catalogue_variants
    validates :weight, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10}

    # Custom validation
    validate :update_availability
    validate :has_images, on: :create, if: -> { self.active? }
    validate :has_remained_any_image_on_update, on: :update, if: -> { self.active? }
    validate :has_tax, if: -> { self.active? }
    validate :duplicate_variant
    validate :check_sale_price, :validate_manufacture_date

    # Callbacks
    before_create :track_event
    before_save :set_stock_qty, :check_product_quantity, :set_current_availablity,
                :calculate_tax_amount, :update_available_price
    after_update :update_orders
    after_save :add_system_sku, :update_default_variant, :inventory_low_stock_mailings
    after_save :send_notification, if: -> { self.saved_change_to_availability? && self.in_stock? && self.product_notifies.present? }
    after_save :remove_draft_products_from_cart, if: -> { self.draft? }
    after_destroy :destroy_wishlist_items

    # Scopes
    scope :latest, -> { order(created_at: :desc) }
    scope :latest_ten, -> { order(created_at: :desc).limit(10) }
    scope :popular, -> { order(sold: :desc) }
    scope :recommended, -> { where(recommended: true) }
    scope :discounted_items, -> { where(on_sale: true) }


    def duplicate_variant
      self.catalogue_variants.each do |variant|
        variant_properties = variant.catalogue_variant_properties
        unless variant_properties.length == variant_properties.map(&:variant_id).uniq.length
          self.errors.add(:variant, "can't have duplicate properties")
          return
        end
      end

      arr = []
      self.catalogue_variants.each_with_index do |variant, i|
        variant.catalogue_variant_properties.each{|a| arr << {variant: i+1, variant_id: a.variant_id, variant_property_id: a.variant_property_id}}
      end
      group = arr.group_by{|a| a[:variant]}

      group.each{|k,v| v.each{|_hash| _hash.delete(:variant)}}
      if group.values.combination(2).any? {|a, b| a == b }
        self.errors.add(:variant, "Two variant can't have similar properties")
      end

    end

    def track_event
      Analytics.track(user_id: ENV["HOST_URL"].split("-")[1],event: 'New Products Created')
    end

    def average_rating
      reviews = self.reviews.where(is_published: true)
      return 0 if reviews.size.zero?

      total_rating = 0
      reviews.each do |r|
        total_rating += r.rating
      end
      (total_rating.to_f / reviews.size.to_f).to_f.round(2)
    end

    def update_availability
      stock_qty.to_i < 1 ? self.availability = "out_of_stock" : self.availability = "in_stock"
    end

    def has_images
      errors.add(:base, 'must add at least one image') if self.attachments.blank? && Rails.env != 'test'
    end

    def has_remained_any_image_on_update
      attachments_to_delete = self.attachments.select{|att| att._destroy == true}
      persisted_obj = BxBlockCatalogue::Catalogue.find(self.id)
      remaining_attachments = persisted_obj.attachments.where.not(id: attachments_to_delete.pluck(:id))
      if remaining_attachments.count == 0
        errors.add(:base, 'must add at least one image') if self.attachments.blank? || self.attachments.any?{|att| att.cropped_image.blank?}
      end
    end

    # def has_catalogue_variants
    #   errors.add(
    #     :base, 'must add at least one product variant'
    #   ) unless self.catalogue_variants.present?
    # end

    def validate_manufacture_date
      return if manufacture_date.blank?
      if manufacture_date >= Date.today
        errors.add(:manufacture_date, "can't be future dates.")
      end
    end

    def check_sale_price
      if self.sale_price.present? && (self.sale_price.to_f > self.price.to_f)
        errors.add(:sale_price, 'can not be greater then price')
      end
    end

    def add_system_sku
      sku = Integer(self.sku) rescue nil
      update_column(:sku, format('COD%.7d', id)) if self.sku.blank? || sku.present?
    end

    def update_default_variant
      # return unless catalogue_variants.find_by(is_default: true)

      # catalogue_variants.first.update!(is_default: true)
    end

    def available_stock_quantity
      self.stock_qty.to_i - self.block_qty.to_i
    end

    def update_available_price
      self.available_price = self.on_sale == true ? self.sale_price : self.price
    end

    def set_stock_qty
      if catalogue_variants.present?
        stock_qty = catalogue_variants.map(&:stock_qty).sum
        self.stock_qty = stock_qty
      end
    end

    def check_product_quantity
      out_of_stock! if (stock_qty.present? && stock_qty.to_i - block_qty.to_i <= 1 && stock_qty.to_i < 1) && in_stock?
      in_stock! if (stock_qty.present? && stock_qty.to_i - block_qty.to_i >= 1) && out_of_stock?
    end

    def set_current_availablity
      available_in_stock = stock_qty.present? && self.available_stock_quantity >= 1
      self.availability = available_in_stock ? 'in_stock' : 'out_of_stock'
    end

    def calculate_tax_amount
      if self.catalogue_variants.blank?
        tax = self.tax
        return unless tax.present?
        price = self.sale_price.present? ? self.sale_price : self.price
        tax_value = (price.to_f * 100) / (100 + tax.tax_percentage.to_f)
        tax_charge = price - tax_value
        self.tax_amount = tax_charge.round(2)
        self.price_including_tax = price.to_f.round(2)
      end
    end

    def destroy_wishlist_items
      BxBlockWishlist::WishlistItem.by_catalogue_id(self.id).destroy_all
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

    def remove_draft_products_from_cart
      BxBlockOrderManagement::OrderItem.where(catalogue: self).or(BxBlockOrderManagement::OrderItem.where(catalogue_variant: self.catalogue_variants)).destroy_all
    end

    def update_orders
      order_items = BxBlockOrderManagement::OrderItem.where(catalogue_id: self.id)
      BxBlockOrderManagement::UpdateCartValueOnCatalogueUpdate.new(order_items).call
    end

    def send_notification
      user_ids = self.product_notifies.pluck(:account_id)
      message = "#{name} is now available in stock."
      user_ids.each do |user_id|
        user = AccountBlock::Account.find_by(id: user_id)
        CatalogueVariantMailer.with(host: $hostname).product_stock_notification(self, user).deliver_now if user.present? && user.email.present?
        BxBlockNotification::SendNotification.new("", message, 'PRODUCT IS BACK', user , { catalogue_id: id, notification_key: 'PRODUCT_IS_IN_STOCK'}).call if user.present? && user.email.present?
      end
      self.product_notifies.destroy_all
    end
  end
end

