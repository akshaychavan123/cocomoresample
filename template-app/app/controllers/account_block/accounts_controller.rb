module AccountBlock
  class AccountsController < ApplicationController
    include BuilderJsonWebToken::JsonWebTokenValidation
    before_action :validate_json_web_token, only: [:reset_password, :reset_sms_account_password, :update_account, :connected_social_accounts, :remove_uuid, :disconnect_social_account]
    def create
      case params[:data][:type] #### rescue invalid API format
      when 'sms_account'
        validate_json_web_token

        begin
          @sms_otp = SmsOtp.find(@token&.id)
        rescue ActiveRecord::RecordNotFound => e
          return render json: {errors: [
            {phone: 'Confirmed phone number was not found'},
          ]}, status: :unprocessable_entity
        end

        params[:data][:attributes][:full_phone_number] =
          @sms_otp.full_phone_number
        @account = SmsAccount.new(jsonapi_deserialize(params))
        @account.activated = true
        if @account.save
          render json: SmsAccountSerializer.new(@account, meta: {
            token: encode(@account.id)
          }).serializable_hash, status: :created
        else
          render json: {errors: format_activerecord_errors(@account.errors)},
                 status: :unprocessable_entity
        end

      when 'email_account'
        validate_json_web_token
        begin
          @email_otp = EmailOtp.find(@token&.id)
        rescue ActiveRecord::RecordNotFound => e
          return render json: {errors: [
            {email: 'Confirmed email was not found'},
          ]}, status: :unprocessable_entity
        end
        if params[:data][:attributes][:email] == @email_otp.email
          @account = EmailAccount.new(jsonapi_deserialize(params))
          @account.activated = true
          if @account.save
            BxBlockEmailNotifications::UserMailer.with(host: $hostname).welcome_email(@account).deliver_now
            render json: EmailAccountSerializer.new(@account, meta: {
              token: encode(@account.id)
            }).serializable_hash, status: :created
          else
            render json: {errors: format_activerecord_errors(@account.errors)},
                   status: :unprocessable_entity
          end
        else
          render json: {errors: "Confirmed email was not found"},
                 status: :unprocessable_entity
        end

      when 'guest_account'
        @account = Account.create(full_name: 'guest',
                                  email: "guest_#{Time.now.to_i}#{rand(100)}@example.com",
                                  uuid: params[:data][:attributes][:uuid], guest: true)
        # render json: {account: @account}, status: :created
        render json: AccountSerializer.new(@account, meta: {
          token: encode(@account.id),
        }).serializable_hash, status: :created

      else
        render json: {errors: [
          {account: 'Invalid Account Type'},
        ]}, status: :unprocessable_entity
      end
    end

    def verify_email
      json_params = jsonapi_deserialize(params)
      account = EmailAccount.find_by_email(json_params["email"])
      email_otp_data = AccountBlock::EmailOtp.where(email: json_params["email"])&.first
      if account.present?
        @email_otp = EmailOtp.find_or_initialize_by(email: json_params["email"])
        @email_otp.full_name = json_params['full_name'] if json_params['full_name'].present?
        @email_otp.activated = false
        if @email_otp.save
          render json: EmailOtpSerializer.new(@email_otp, meta: {
            token: BuilderJsonWebToken.encode(@email_otp.id),
          }).serializable_hash, status: :created
        else
          render json: {errors: format_activerecord_errors(@email_otp.errors)},
                 status: :unprocessable_entity
        end
      elsif email_otp_data.present? && !email_otp_data.activated
        return render json: {errors: [
          {pin: "Sorry, You need to confirm your account first."},
        ]}, status: :unprocessable_entity
      else
        return render json: {errors: [{phone: 'Email was not found'}]}, status: :unprocessable_entity
      end
    end

    def reset_password
      begin
        @email_otp = EmailOtp.find(@token&.id)
      rescue ActiveRecord::RecordNotFound => e
        return render json: {errors: [
          {email: 'Verified email was not found'},
        ]}, status: :unprocessable_entity
      end
      account = EmailAccount.find_by_email(@email_otp.email)
      if account.authenticate(params[:data][:password])
        render :json => {:errors => [message: 'The password is already been used, please try again with another password']},
               :status => :unprocessable_entity
      else
        if account.update(password_update_params)
          # BxBlockEmailNotifications::UserMailer.with(host: $hostname).password_changed(account).deliver_now
          render json: AccountSerializer.new(account, meta: {
            message: 'Your password has been changed successfully.'
          }).serializable_hash, status: :ok
        else
          render :json => {:errors  => account.errors},
                 :status => :unprocessable_entity
        end
      end
    end

    def reset_sms_account_password
      begin
        @sms_otp = SmsOtp.find(@token&.id)
      rescue ActiveRecord::RecordNotFound => e
        return render json: {errors: [
          {full_phone_number: 'Verified phone number was not found'},
        ]}, status: :unprocessable_entity
      end
      account = SmsAccount.find_by_full_phone_number(@sms_otp.full_phone_number)
      if account.authenticate(params[:data][:password])
        render :json => {:errors => [message: 'The password is already been used, please try again with another password']},
               :status => :unprocessable_entity
      else
        if account.update(password_update_params)
          # BxBlockEmailNotifications::UserMailer.with(host: $hostname).password_changed(account).deliver_now
          render json: AccountSerializer.new(account, meta: {
            message: 'Your password has been changed successfully.'
          }).serializable_hash, status: :ok
        else
          render :json => {:errors  => account.errors},
                 :status => :unprocessable_entity
        end
      end
    end

    def update_account
      begin
        @account = AccountBlock::Account.find(@token.id)
      rescue ActiveRecord::RecordNotFound => e
        return render json: {errors: [
          {email: 'Account not found'},
        ]}, status: :unprocessable_entity
      end
      if @account.update(account_update_param)
        render json: AccountSerializer.new(@account, meta: {
          message: 'Your account has been updated successfully.'
        }).serializable_hash, status: :ok
      else
        render :json => {:errors  => @account.errors},
               :status => :unprocessable_entity
      end
    end

    def connected_social_accounts
      accounts = SocialAccount.where(uuid: params[:uuid])
      serializer = SocialAccountSerializer.new(accounts)
      render :json => serializer.serializable_hash
    end

    def remove_uuid
      accounts = SocialAccount.where(uuid: params[:uuid])
      if accounts&.update_all(uuid: nil)
        render json: {
          message: "Social account disconnected successfully"
        }, status: :ok
      else
        render :json => {
          :errors  => "Record not found"
        }, :status => :unprocessable_entity
      end
    end

    def disconnect_social_account
      account = SocialAccount.find_by access_token: params[:access_token]
      if account&.update(access_token: nil, uuid: nil)
        render json: {
          message: "Logout successfully"
        }, status: :ok
      else
        render :json => {
          :errors  => "Record not found"
        }, :status => :unprocessable_entity
      end
    end

    # this api for create admin_user
    def admin_user_creation
      admin_user = AdminUser.new(email: params[:email], password: params[:password], password_confirmation: params[:password_confirmation])
      if admin_user.save
        render json: admin_user, status: :created
      else
        render json: {errors: [{admin_user: 'Admin user not created'}]}, status: :unprocessable_entity
      end
    end

    private

    def password_update_params
      params.require(:data).permit \
        :password,
        :password_confirmation
    end

    def account_update_param
      params.permit(:fcm_token)
    end

    def format_activerecord_errors(errors)
      result = []
      errors.each do |attribute, error|
        result << { attribute => error }
      end
      result
    end

    def encode(id, data = {}, expiration = nil)
      BuilderJsonWebToken.encode(id, data, expiration)
    end
  end
end
