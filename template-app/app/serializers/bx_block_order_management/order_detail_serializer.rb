module BxBlockOrderManagement
  class OrderDetailSerializer < BuilderBase::BaseSerializer

    # belongs_to :account, serializer: AccountBlock::AccountSerializer, if: Proc.new {|rec, params| params[:user].present? }
    # has_many :order_items, serializer: BxBlockOrderManagement::OrderItemSerializer
    # has_many :delivery_addresses, serializer: AddressesSerializer

    attributes *[
      :id,
      :order_number,
      :amount

    ]
  end
end
