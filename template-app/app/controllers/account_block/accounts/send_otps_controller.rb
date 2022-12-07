# frozen_string_literal: true

module AccountBlock
  module Accounts
    class SendOtpsController < ApplicationController
      # skip_before_action :verify_authenticity_token

      def create
        case params[:data][:type]
          when 'sms_account'
             if params[:data][:process] == "reset_password"
              json_params = jsonapi_deserialize(params)
              account = AccountBlock::SmsAccount.find_by(full_phone_number: json_params['full_phone_number'], activated: true)
              sms_otp_data = AccountBlock::SmsOtp.find_by(full_phone_number: json_params['full_phone_number'])
              if account.present?
                text_message = "Someone has requested an otp to change your password.\r\n\r\n<sms_pin> is your OTP for #{BxBlockStoreProfile::BrandSetting.last&.heading} Forgot Password.\r\n\r\nIf you didn't request this, please ignore this message.\r\n"
                send_sms_otp(text_message)
              elsif sms_otp_data.present? && !sms_otp_data.activated
                return render json: {errors: [
                  {pin: "Sorry, You can not reset your password as your account is not verified. Please do signup again."},
                ]}, status: :unprocessable_entity
              else
                render json: {errors: [
                {account: "The phone number you've entered is not registered with us."},
                ]}, status: :unprocessable_entity
              end
            elsif params[:data][:process] == "register"
              json_params = jsonapi_deserialize(params)
              account = AccountBlock::SmsAccount.find_by(
                full_phone_number: json_params['full_phone_number'],
                activated: true)
              return render json: {errors: [{
              account: 'Account already activated',
              }]}, status: :unprocessable_entity unless account.nil?
              text_message = "Welcome to #{BxBlockStoreProfile::BrandSetting.last&.heading}\r\n\r\nYour account must be verified before you login to the Application.\r\n\r\nUse the following OTP to verify your account with us so that you can login to our Application.\r\n\r\n<sms_pin>\r\n\r\nTo login into the application, enter your Email/Phone and password.\r\n\r\nThank You, #{BxBlockStoreProfile::BrandSetting.last&.heading}!"
              send_sms_otp(text_message)
            end
          when 'email_account'
            if params[:data][:process] == "reset_password"
              json_params = jsonapi_deserialize(params)
              account = AccountBlock::EmailAccount.find_by(email: json_params['email'], activated: true)
              email_otp_data = AccountBlock::EmailOtp.find_by(email: json_params['email'])
              if account.present? && account.social_auths.present?
                return render json: {errors: [{account: "You are already registered with us using #{account.social_auths.pluck(:provider).join(',')}."},
                ]}, status: :unprocessable_entity
              elsif account.present?
                send_email_otp
              elsif email_otp_data.present? && !email_otp_data.activated
                return render json: {errors: [
                  {pin: "Sorry, You can not reset your password as your account is not verified. Please do signup again."},
                ]}, status: :unprocessable_entity
              else
                render json: {errors: [
                  {account: "The email you've entered is not registered with us."},
                ]}, status: :unprocessable_entity
              end
            elsif params[:data][:process] == "register"
              send_email_otp
            else
              render json: {errors: [
                {account: 'Entered process is invalid.'},
              ]}, status: :unprocessable_entity
            end
          else
            render json: {errors: [
              {account: 'Invalid Account Type'},
            ]}, status: :unprocessable_entity
          end
      end

      private

      def send_sms_otp(text_message="")
        otp_params = jsonapi_deserialize(params)
        @account = AccountBlock::Account.where(full_phone_number: otp_params['full_phone_number'])&.first
        @sms_otp = SmsOtp.find_or_initialize_by(full_phone_number: otp_params['full_phone_number'])
        @sms_otp.full_name = otp_params['full_name'] if otp_params['full_name'].present?
        @sms_otp.phone_number = otp_params['email'] if otp_params['email'].present?
        @sms_otp.activated = false unless @account.present? && params[:data][:process] == "register"
        #@sms_otp.activated = true
        if @sms_otp.save
          @sms_otp.send_pin_via_sms(text_message)
          render json: SmsOtpSerializer.new(@sms_otp, meta: {
            token: BuilderJsonWebToken.encode(@sms_otp.id),
          }).serializable_hash, status: :created
        else
          render json: {errors: format_activerecord_errors(@sms_otp.errors)},
                 status: :unprocessable_entity
        end
      end

      def send_email_otp
        otp_params = jsonapi_deserialize(params)
        @account = AccountBlock::Account.where(email: otp_params['email']).or(AccountBlock::Account.where(phone_number: otp_params['email']))&.first

        @email_otp = EmailOtp.find_or_initialize_by(email: otp_params['email'])
        @email_otp.full_name = otp_params['full_name'] if otp_params['full_name'].present?
        @email_otp.phone_number = otp_params['phone_number'] if otp_params['phone_number'].present?
        @email_otp.activated = false unless @account.present? && params[:data][:process] == "register"
        # @email_otp.activated = true
        if params[:data][:process] == "register" && (AccountBlock::Account.exists? email: otp_params['email'])
          return render json: {errors: [
            {account: "Email has already been taken."},
          ]}, status: :unprocessable_entity
        elsif params[:data][:process] == "register" && @account.present? && @email_otp.present? && @email_otp.activated
          return render json: {errors: [
            {account: "You are already registered with us using this email."},
          ]}, status: :unprocessable_entity
        elsif params[:data][:process] == "register" && @account.present? && @account.social_auths.present?
          return render json: {errors: [
            {account: "You are already registered with us using #{@account.social_auths.pluck(:provider).join(',')}."},
          ]}, status: :unprocessable_entity
        elsif @email_otp.save
          if params[:data].present? && params[:data][:process] == "reset_password"
            BxBlockEmailNotifications::UserMailer.with(host: $hostname).password_changed(@email_otp).deliver_now
          else
            BxBlockEmailNotifications::UserMailer.with(host: $hostname).new_account_otp_verification(@email_otp).deliver_now
          end
          render json: EmailOtpSerializer.new(@email_otp, meta: {
            token: BuilderJsonWebToken.encode(@email_otp.id),
          }).serializable_hash, status: :created
        else
          render json: {errors: format_activerecord_errors(@email_otp.errors)},
                 status: :unprocessable_entity
        end
      end

      def format_activerecord_errors(errors)
        result = []
        errors.each do |attribute, error|
          result << { attribute => error }
        end
        result
      end
    end
  end
end
