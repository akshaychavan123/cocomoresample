module BxBlockPaymentRazorpay
  class OrderDetailsSerializer < BuilderBase::BaseSerializer
    attributes :id, :entity, :amount, :amount_paid, :amount_due, :currency,
               :receipt, :offer_id, :status, :attempts, :notes, :created_at
  end
end
