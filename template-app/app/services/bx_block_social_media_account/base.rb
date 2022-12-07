# frozen_string_literal: true

module BxBlockSocialMediaAccount
  class Base
    attr_reader :provider, :data, :access_token, :uid

    def initialize(params)
      @name = params[:name] if params[:name].present?
      @userIdentity = params[:userIdentity] if params[:userIdentity].present?
      @provider = self.class.name.split('::').last.downcase
      @client = HTTPClient.new
      @access_token = params['access_token'].presence
      puts "ACCESS TOKEN IS - #{@access_token}"
      get_data if @access_token.present?
    end

    def authorized?
      @access_token.present? && !@data.key?('error')
    end
  end
end
