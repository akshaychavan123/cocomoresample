# frozen_string_literal: true

require 'digest'

module BxBlockPaymentRazorpay
  class RazorpaysController < ApplicationController
    before_action :is_guest
    skip_before_action :validate_json_web_token, :only => [:payment_callback]
    skip_before_action :get_user, :only => [:payment_callback]
    skip_before_action :is_guest, :only => [:payment_callback]

    def create
      order = BxBlockOrderManagement::Order.find(params[:order_id])

      if order.present?
        amount = (order.total.to_f * 100).to_i
        receipt = Digest::MD5.hexdigest(order.order_number.to_s)
        account_id = ENV['RAZORPAY_PARTNER_ACCOUNT_ID']
        razorpay_order = if ENV['RAZORPAY_PARTNER_ACCOUNT_ID'].present?
                           BxBlockPaymentRazorpay::Payment.create(amount, 'INR', receipt, account_id)
                         else
                           BxBlockPaymentRazorpay::Payment.create(amount, 'INR', receipt)
                         end

        if razorpay_order[:success] == false
          render json: {
            success: false,
            message: razorpay_order[:message]
          }, status: (razorpay_order[:http_status] || 200) and return
        elsif razorpay_order[:data].status == 'created'
          # order.order_transactions.create!(
          #   account_id: @current_user.id,
          #   razorpay_order_id: razorpay_order[:data].id,
          #   payment_id: nil,
          #   razorpay_signature: nil,
          #   status: "pending_capture",
          #   amount: amount
          # )
          # invoice = Razorpay::Invoice.create(
          #   amount: amount,
          #   currency: 'INR',
          #   description: 'Invoice for order',
          #   type: 'link',
          #   callback_url: "http://localhost:3000/bx_block_payment_razorpay/razorpays/payment_callback?order_id=#{order.id}",
          #   callback_method: 'get'
          # )

          order.update(razorpay_order_id: razorpay_order[:data].id, order_date:Time.current.utc, source:'card')

          render json: {
            success: true,
            data:
              {
                order: BxBlockOrderManagement::OrderSerializer.new(order).serializable_hash,
                order_number: razorpay_order[:data].id
                  }
          }, status: 200
        end
      else
        render json: { success: false, errors: 'Order Not Found.' },
               status: :not_found
      end
    end

    def order_details
      if params[:order_id].present?
        details = Payment.order_details(params[:order_id])

        render json: {
          success: true,
          details: OrderDetailsSerializer.new(details).serializable_hash
        }
      else
        render json: { error: { message: 'order_number param required' } },
               status: :not_found
      end
    end

    def verify_signature
      # verify_result = Payment.verify(
      #   order.latest_payment.order_id,
      #   order.latest_payment.payment_id,
      #   order.latest_payment.razorpay_signature
      # )
      verify_result = Payment.verify(
        params[:razorpay_order_id],
        params[:razorpay_payment_id],
        params[:razorpay_signature]
      )

      order = BxBlockOrderManagement::Order.find_by(razorpay_order_id: params[:razorpay_order_id])
      if verify_result && order.present?
        # order.latest_payment.update(status: 'verified')
        amount = (order.total.to_f * 100).to_i
        order.order_transactions.create!(
          account_id: @current_user.id,
          razorpay_order_id: params[:razorpay_order_id],
          payment_id: params[:razorpay_payment_id],
          razorpay_signature: params[:razorpay_signature],
          status: "verified",
          amount: amount
        )
        order_status_id =  BxBlockOrderManagement::OrderStatus.find_by(status:"placed").id
        order.place_order! unless order.placed?
        order.update(order_status_id: order_status_id, placed_at: Time.current) unless order.placed?

        order_status_id =  BxBlockOrderManagement::OrderStatus.find_by(status:"confirmed").id
        order.update(source: "Razorpay", order_status_id: order_status_id, confirmed_at: Time.current, placed_at: Time.current, order_date: Time.current) unless order.confirmed?
        render json: { success: verify_result, data: { order: order } }, status: :ok
      else
        render json: { error: { message: 'Somethig went wrong' } },
               status: :not_found
      end

    end

    def capture
      order = BxBlockOrderManagement::Order.find(params[:order_id])

      if order.present?
        payment_id = order.latest_payment.payment_id
        amount = (order.total.to_f * 100).to_i

        response = Payment.capture(payment_id, amount)
        order.latest_payment.update(state: 'captured')

        render json: CaptureResponseSerializer.new(response).serializable_hash, status: :ok
      else
        render json: { success: false, errors: 'Order Not Found.' },
               status: :not_found
      end
    end

    def refund
      order = BxBlockOrderManagement::Order.find_by(id: params[:order_id])
      render(json: { message: "No order found!" }, status: 400) && return if order.nil?

      amount = (order.total.to_f * 100).to_i

      payment_id = order.latest_payment.payment_id
      payment = Payment.refund(payment_id, amount)
      render(json: { message: "No payment found!" }, status: 400) && return if payment.nil?

      render json: {
        success: true,
        message: "The payment amount has been refunded successfully."
      }, status: 200
    end

    def payment_callback
      payment_id = params[:razorpay_payment_id]
      signature = params[:razorpay_signature]
      payment = Razorpay::Payment.fetch(payment_id)
      last_transacted_order = BxBlockOrderManagement::OrderTransaction.where(order_id: params[:order_id]).order(:created_at).last
      if payment.status == 'captured' && last_transacted_order.present?
        last_transacted_order.update(
          status: 'captured',
          payment_id: payment_id,
          razorpay_signature: signature,
          payment_provider: 'razorpay'
        )
        render json: {
          success: true,
          message: "The payment amount has been captured successfully."
        }, status: 200
      else
        render json: { error: { message: 'Order is not found' } },
               status: :not_found
      end
    end

    private

      def is_guest
        if @current_user.guest?
          return render json: {message: "Please login or signup to access services"}, status: :unprocessable_entity
        end
      end

  end
end
