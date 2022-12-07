# frozen_string_literal: true

module BxBlockSocialMediaAccount
  class Google < BxBlockSocialMediaAccount::Base
    ACCESS_TOKEN_URL = 'https://accounts.google.com/o/oauth2/token'
    DATA_URL = "https://www.googleapis.com/oauth2/v3/userinfo"

    def get_names
      names = data[:name].try(:split).to_a
      [data[:given_name] || names.first, data[:family_name] || names.last]
    end

    def get_data
      response = @client.get(DATA_URL, access_token: @access_token)
      @data = JSON.parse(response.body).with_indifferent_access
      @uid = @data[:id] ||= @data[:sub]
      @data
    end

    def formatted_user_data
      {
        provider:       'google',
        token:          @access_token,
        uid:            @data['id'],
        first_name:     @data['given_name'],
        last_name:      @data['family_name'],
        email:          @data['email'],
        image_url:      @data['picture']&.gsub('?sz=50', ''),
        google_profile: @data['profile'],
        display_name:   @data['name']
      }
    end
  end
end
