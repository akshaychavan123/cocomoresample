module BxBlockStripeIntegration
  class EmailAccountSerializer
    include FastJsonapi::ObjectSerializer

    attributes *[
        :username,
        :email,
        :stripe_id,
        :activated,
    ]
  end
end
