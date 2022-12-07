module BxBlockSocialMediaAccount
  class SocialAuthsController < ApplicationController
    include BuilderJsonWebToken::JsonWebTokenValidation
    before_action :validate_json_web_token, only: [:index, :connect, :destroy]
    before_action :get_user, except: [:social_login]
    before_action :fetch_social_auth, only: [:destroy]

    def social_login
      account_params = jsonapi_deserialize(params)
      @oauth = "BxBlockSocialMediaAccount::#{account_params['provider'].titleize}".constantize.new(account_params)
      if AccountBlock::Account.is_exists? @oauth.formatted_user_data
        if @oauth.authorized?
          user = BxBlockSocialMediaAccount::ManageSocialAuth.new(@oauth.formatted_user_data).call
          if user
            AccountBlock::UpdateUserData.new(params,user).call
            user
            render json: AccountBlock::SocialAccountSerializer.new(user, meta: {
              token: encode(user.id),
            }).serializable_hash, status: :created
          else
            return render json: {errors: [
              {email: "You are already registered with us using #{account_params['provider']} or email"},
            ]}, status: :unprocessable_entity
          end
        else
          return render json: {errors: [
            {email: "There was an error with #{account_params['provider']}. please try again."},
            ]}, status: :unprocessable_entity
        end
      else
        return render json: {errors: [
          {email: "You are already registered with us using this email."},
          ]}, status: :unprocessable_entity
      end
    end

    def index
      social_auths = @current_user.social_auths
      render json: {
            data:
            {
              social_accounts: BxBlockSocialMediaAccount::SocialAuthSerializer.new(social_auths, { params: { host: request.protocol + request.host_with_port } }),
              account: AccountBlock::AccountSerializer.new(@current_user, { params: { host: request.protocol + request.host_with_port } })
            }
          }, status: "200"
    end

    def connect
      begin
        account_params = jsonapi_deserialize(params)
        social_auth = SocialAuth.create_from_provider_data(account_params)
        render json: {
            data:
            {
              social_account: BxBlockSocialMediaAccount::SocialAuthSerializer.new(social_auth, { params: { host: request.protocol + request.host_with_port } }),
              account: AccountBlock::AccountSerializer.new(@current_user, { params: { host: request.protocol + request.host_with_port } })
            }
          }, status: "200"
      rescue Exception => e
        render :json => {errors: [
          {social_auth: e.message}
        ]},:status => :unprocessable_entity
      end
    end

    def destroy
      if @social_auth.present?
        @social_auth.destroy!
        render json: { data: {
          message: "Social account disconnected successfully"
          }
        }, status: :ok
      else
        return render json: {errors: [
          {social_auth: "Social account is not found"},
          ]}, status: :unprocessable_entity
      end
    end

    private

    def get_user
      @current_user = AccountBlock::Account.find(@token.id)
    end

    def fetch_social_auth
      @social_auth = BxBlockSocialMediaAccount::SocialAuth.find_by(id: params[:id])
    end

    def encode(id)
      BuilderJsonWebToken.encode id
    end
  end
end
