module BxBlockStripeIntegration
  class PaymentMethodSerializer
    include FastJsonapi::ObjectSerializer

    attributes *[
        :account_id,
        :card_token,
        :is_primary
    ]
  end
end
