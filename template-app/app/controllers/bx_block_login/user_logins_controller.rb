module BxBlockLogin
  class UserLoginsController < ApplicationController

    def create
      @account = AccountBlock::Account.where("LOWER(email)= ?", params[:email_or_mobile].to_s.downcase)
                   .or(AccountBlock::Account.where(full_phone_number: params[:email_or_mobile]))&.first

      @email_otp = AccountBlock::EmailOtp.where(email: params[:email_or_mobile])&.first
      @sms_otp = AccountBlock::SmsOtp.where(full_phone_number: params[:email_or_mobile])&.first

      if @email_otp.present? && !@email_otp.activated && !@account.present?
        return render json: {errors: [
          {pin: "Sorry, You need to confirm your account first."},
        ]}, status: :unprocessable_entity
      elsif @sms_otp.present? && !@sms_otp.activated && !@account.present?
        return render json: {errors: [
          {pin: "Sorry, You need to confirm your account first."},
        ]}, status: :unprocessable_entity
      elsif @account.present? && @account&.authenticate(params[:password])
        Rails.logger.error ">>>>>>>>>>>>>>>>>User Activated #{@account.activated}>>>>>>>>>>>>"

        return render json: {
          errors: [{account: "Account is InActive,Please contact to admin"}]
        }, status: :unprocessable_entity unless @account.activated

        AccountBlock::UpdateUserData.new(params,@account).call
        render json: AccountBlock::AccountSerializer.new(@account, meta: {
          message: 'You are successfully logged in',
          token: BuilderJsonWebToken.encode(@account.id),
        }).serializable_hash, status: :ok
      # elsif @account.present? && @account.social_auths.present?
      #   return render json: {errors: [
      #     {pin: "You are already registered with us using #{@account.social_auths.pluck(:provider).join(',')}."},
      #   ]}, status: :unprocessable_entity
      else
        return render json: {errors: [
          {pin: "The email/phone number or password you've entered is incorrect."},
        ]}, status: :unprocessable_entity
      end
    end

  end
end
