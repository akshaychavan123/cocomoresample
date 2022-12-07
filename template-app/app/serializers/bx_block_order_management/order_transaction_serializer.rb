module BxBlockOrderManagement
  class OrderTransactionSerializer < BuilderBase::BaseSerializer
    attributes :id, :account_id, :created_at
  end
end
