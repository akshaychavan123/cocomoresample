module BxBlockProfile
  class ApplicationController < BuilderBase::ApplicationController
    include BuilderJsonWebToken::JsonWebTokenValidation
    before_action :validate_json_web_token
    before_action :current_user

    def current_user
      @current_user = AccountBlock::Account.find(@token&.id)
    end
  end
end
