# == Schema Information
#
# Table name: delivery_addresses
#
#  id             :bigint           not null, primary key
#  account_id     :bigint           not null
#  address        :string
#  name           :string
#  flat_no        :string
#  zip_code       :string
#  phone_number   :string
#  deleted_at     :datetime
#  latitude       :float
#  longitude      :float
#  residential    :boolean          default(TRUE)
#  city           :string
#  state_code     :string
#  country_code   :string
#  state          :string
#  country        :string
#  address_line_2 :string
#  address_type   :string           default("home")
#  address_for    :string           default("shipping")
#  is_default     :boolean          default(FALSE)
#  landmark       :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
module BxBlockOrderManagement
  class DeliveryAddress < BxBlockOrderManagement::ApplicationRecord
    self.table_name = :delivery_addresses

    belongs_to :account, class_name: "AccountBlock::Account", optional: true
    belongs_to :address_state, class_name: "BxBlockOrderManagement::AddressState", optional: true
    has_many :delivery_address_orders, dependent: :destroy
    has_many :orders, through: :delivery_address_orders

    validates :name, :flat_no, :address, :zip_code, :phone_number, :city, :country, presence: true
    validates :phone_number, format: { with: /^(?:\+?\d{1,3}\s*-?)?\(?(?:\d{3})?\)?[- ]?\d{3}[- ]?\d{4}$/, :multiline => true, message: ' is not valid' }
    validates :address_for, presence: true, inclusion: { in: %w(shipping billing billing_and_shipping) }

    before_save :assign_state

    enum country: ['india', 'uk']

    scope :rest_addresses, -> (address_id){ where.not(id: address_id) }
    scope :billing_and_shipping, -> { where(address_for: "billing_and_shipping") }
    scope :delivery_add, -> { where(address_for: ['shipping','billing_and_shipping']) }

    def full_address
      "#{self.flat_no} #{self.address} #{self.address_line_2} #{self.city} #{self.state} #{self.country} #{self.zip_code}"
    end

    private

    def assign_state
      if self.address_state_id.present?
        self.state = self.address_state.name
      end
    end

  end
end
