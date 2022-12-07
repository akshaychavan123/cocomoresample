module BxBlockPaymentRazorpay
  class CaptureResponseSerializer < BuilderBase::BaseSerializer
    attributes :id, :entity, :amount, :currency, :status, :order_id,
               :invoice_id, :international, :method, :captured, :description,
               :email, :contact, :error_code, :error_description
  end
end
