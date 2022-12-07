module BxBlockStripeIntegration
  class PaymentSerializer
    include FastJsonapi::ObjectSerializer

    attributes *[
        :ammount
    ]
  end
end
