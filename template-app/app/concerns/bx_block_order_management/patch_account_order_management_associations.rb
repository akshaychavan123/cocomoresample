module BxBlockOrderManagement
  module PatchAccountOrderManagementAssociations
    extend ActiveSupport::Concern

    included do
      has_many :orders, class_name: "BxBlockOrderManagement::Order", dependent: :destroy
      has_many :order_transactions, class_name: "BxBlockOrderManagement::OrderTransaction", dependent: :nullify
      has_many :delivery_addresses, -> { order('created_at DESC') }, class_name: "BxBlockOrderManagement::DeliveryAddress", dependent: :destroy
    end
  end
end
