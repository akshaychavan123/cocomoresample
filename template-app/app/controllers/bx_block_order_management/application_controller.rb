module BxBlockOrderManagement
  class ApplicationController < BuilderBase::ApplicationController
    include BuilderJsonWebToken::JsonWebTokenValidation

    before_action :validate_json_web_token, :unless => :get_monthly_orders?
    before_action :get_user

    rescue_from ActiveRecord::RecordNotFound, :with => :not_found

    private

    def not_found
      render :json => {'errors' => ['Record not found']}, :status => :not_found
    end

    def get_user
      @current_user = AccountBlock::Account.find(@token.id) if @token.present?
    end

    def get_monthly_orders?
      params[:action] == "get_monthly_orders" ? true : false
    end

  end
end
