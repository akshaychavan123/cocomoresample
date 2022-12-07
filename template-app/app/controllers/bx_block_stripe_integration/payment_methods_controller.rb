module BxBlockStripeIntegration
  class PaymentMethodsController < BxBlockStripeIntegration::ApplicationController
    before_action :setup_stripe

    def create_payments
      payment_params = jsonapi_deserialize(params)
      order = BxBlockOrderManagement::Order.find_by(id: payment_params['order_id'])

      if order.present? && (order.in_cart? || order.created?)
        user = current_user
        amount = order.total.to_i * 100
        AccountBlock::EmailAccount.create_stripe_customers(current_user)
        payment_intent = create_payment_intent(amount, params['data']['payment_token'] )
        if payment_intent
          order.update(stripe_payment_method_id: payment_intent['payment_method'])
          render json: {
            message: 'Payment initiated successfull.',
            data: {client_secret: payment_intent['client_secret']}, status: :ok}
        else
          render json: {
            errors: [{
                       account: 'Invalid data format',
                     }],
          }, status: :unprocessable_entity
        end
      end
    end

    def confirm_payment
      payment_params = params
      order = BxBlockOrderManagement::Order.find_by(stripe_payment_method_id: payment_params['data']['stripe_payment_id']) if payment_params['data'].present? && payment_params['data']['stripe_payment_id'].present?
      if order.present?
        @payment_intent = Stripe::PaymentIntent.retrieve(payment_params['data']['payment_intent_id'],)
        if @payment_intent['amount_received'] != 0
          create_order_transaction(order, @payment_intent)
          order_status_id =  BxBlockOrderManagement::OrderStatus.find_by(status:"placed").id
          Rails.logger.error ">>>>>>>>>>>>>>>>>Order Placed #{order.placed?}>>>>>>>>>>>>"
          order.place_order! unless order.placed?
          Rails.logger.error ">>>>>>>>>>>>>>>>>Order Placed #{order.placed?}>>>>>>>>>>>>"
          order.update(order_status_id: order_status_id, placed_at: Time.current) unless order.placed?
          order_status_id =  BxBlockOrderManagement::OrderStatus.find_by(status:"confirmed").id
          order.update(source: "Stripe", order_status_id: order_status_id, confirmed_at: Time.current, placed_at: Time.current, order_date: Time.current) unless order.confirmed?
          proccess_after_payment(order) if  @logistics_configuration = BxBlockApiConfiguration::ApiConfiguration.find_by(configuration_type: '525k').present?
          render json: {data: {message: 'Payment successfull.',order: order}, status: :ok}
        else
          render json: {errors: [{account: 'Invalid data format',}],}, status: :unprocessable_entity
        end
      else
        render json: {errors: [{account: 'Order not found.',}],}, status: :unprocessable_entity
      end
    end

    def create_subscription
      subscription = Stripe::Subscription.create({customer: current_user.stripe_id, items: [{plan: AccountBlock::Account.monthly_plan_key}]})
      update_user = current_user.update(subscription_id: subscription.id, subscription_date: Time.now())
      if update_user
        render json: AccountBlock::EmailAccountSerializer.new(current_user, meta: {
          token: encode(current_user.id),
        }).serializable_hash, status: :created
      else
        render json: {
          errors: [{
                     account: 'Invalid data format',
                   }],
        }, status: :unprocessable_entity
      end
    end

    def cancel_subscription
      cancel_subscription = Stripe::Subscription.delete(current_user.subscription_id)
      update_user = current_user.update(subscription_id: nil, subscription_date: nil)
      if update_user
        render json: AccountBlock::EmailAccountSerializer.new(current_user, meta: {
          token: encode(current_user.id),
        }).serializable_hash, status: :created
      else
        render json: {
          errors: [{
                     account: 'Invalid data format',
                   }],
        }, status: :unprocessable_entity
      end

    end

    private

    def proccess_after_payment(order)
      shipment_params = BxBlockFedexIntegration::ShipmentAttributesCreation.new(order, @payment_intent).call
      shipment_service = BxBlockFedexIntegration::ShipmentService.new
      result = shipment_service.create(shipment_params)
      if result['status'] == "PROPOSED"
        order.update!(shipment_id: result['id'], tracking_url: result['trackingURL'], tracking_number: result['waybill'])
        OpenStruct.new(success?: true, msg: I18n.t('messages.deliveries.success', deliver_by: "FedEx"), code: 200)
      else
        error = I18n.t('messages.deliveries.failed') +  "Error from #{order.deliver_by} "
        OpenStruct.new(success?: false, msg: error, code: 400)
      end
      OpenStruct.new(success?: true, msg: I18n.t('messages.deliveries.success', deliver_by: "FedEx"), code: 200)
    end

    def create_payment_intent(amount, payment_method)
      Stripe::PaymentIntent.create({
                                     customer: current_user.stripe_id,
                                     amount: amount,
                                     currency: 'inr',
                                     payment_method: payment_method,
                                     description: "Software development services",
                                     payment_method_types: ['card'],
                                   })

    end

    def create_order_transaction(order, payment_charge)
      order.order_transactions.create!(
        account_id: current_user.id,
        stripe_payment_id: payment_charge["payment_method"],
        status: "verified",
        amount: payment_charge["amount_received"],
        payment_provider: 'Stripe'
      )
    end

    def encode(id)
      BuilderJsonWebToken.encode id
    end

    private

    def setup_stripe
      stripe_configuration = BxBlockApiConfiguration::ApiConfiguration.find_by(configuration_type: 'stripe')
      Stripe.api_key = stripe_configuration&.api_secret_key
    end
  end
end

