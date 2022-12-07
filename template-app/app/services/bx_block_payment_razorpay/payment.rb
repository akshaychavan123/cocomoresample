module BxBlockPaymentRazorpay
  class Payment
    class << self
      require 'razorpay'

      def create(amount, currency, receipt, account_id= nil)
        setup_razorpay
        response = nil
        if account_id.nil?
          response = Razorpay::Order.create(amount: amount, currency: currency, receipt: receipt)
          # response = Razorpay::Order.create(amount: amount, currency: currency, receipt: receipt)
          # return {success: true, status: 200}
        else
          begin
            response = Razorpay::Order.create(amount: amount, currency: currency, receipt: receipt, account_id: account_id)
            return {success: false, message: response.message, http_status: 400} if !response.respond_to?(:status)
          rescue StandardError =>e
            return {success: false, message: e.message}
          end
        end
        {success: true, data: response}
      end

      def verify(order_id, payment_id, signature)
        setup_razorpay
        payment_response = {
          razorpay_order_id: order_id,
          razorpay_payment_id: payment_id,
          razorpay_signature: signature
        }

        Razorpay::Utility.verify_payment_signature(payment_response)
      end

      def capture(payment_id, capture_amount, currency = 'INR')
        setup_razorpay
        Razorpay::Payment.fetch(payment_id).capture(
          amount: capture_amount,
          currency: currency
        )
      end

      def order_details(order_id)
        setup_razorpay
        Razorpay::Order.fetch(order_id)
      end

      def refund(payment_id, amount)
        setup_razorpay
        Razorpay::Payment.fetch(payment_id).refund({ amount: amount })
      end

      private

      def setup_razorpay
        razorpay_configuration = BxBlockApiConfiguration::ApiConfiguration.find_by(configuration_type: 'razorpay')

        Razorpay.setup(ENV['RAZORPAY_KEY']||razorpay_configuration&.api_key, ENV['RAZORPAY_SECRET']||razorpay_configuration&.api_secret_key)
      end
    end
  end
end
