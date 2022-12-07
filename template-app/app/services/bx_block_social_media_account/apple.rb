# frozen_string_literal: true

module BxBlockSocialMediaAccount
  class Apple < BxBlockSocialMediaAccount::Base
    APPLE_PEM_URL = "https://appleid.apple.com/auth/keys"
    DATA_URL = "https://api.appstoreconnect.apple.com/v1/users"

    def get_data
        jwt = @access_token
        header_segment = JSON.parse(Base64.decode64(jwt.split(".").first))
        alg = header_segment["alg"]
        kid = header_segment["kid"]
        apple_response = Net::HTTP.get(URI.parse(APPLE_PEM_URL))
        apple_certificate = JSON.parse(apple_response)
        keyHash = ActiveSupport::HashWithIndifferentAccess.new(apple_certificate["keys"].select {|key| key["kid"] == kid}[0])
        jwk = JSON::JWK.new(keyHash)
        @data = {}
        token_data = JWT.decode(jwt, jwk.to_key.public_key, true, {algorithm: alg})[0]
        @data = token_data
        @data['id'] = token_data['sub']
        @data['name'] = @name.present? ? @name : @data['email'].split('@')[0]
        @data['userIdentity'] = token_data['sub']
        @data
    end

    def formatted_user_data
      {
        provider:         'apple',
        token:            @access_token,
        email:            @data['email'],
        uid:              @data['id'],
        id:               @data['id'],
        name:             @data['name'],
        display_name:     @data['name']
      }
    end
  end
end
