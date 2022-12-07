# frozen_string_literal: true

module BxBlockSocialMediaAccount
  class Instagram < BxBlockSocialMediaAccount::Base
    DATA_URL = 'https://graph.instagram.com/me'

    def get_data
      response = @client.get(DATA_URL, access_token: @access_token, fields: 'username, account_type, ig_id')
      @data = JSON.parse(response.body).with_indifferent_access
      @data['image_url'] = @data['picture']['data']['url'] if @data['picture'].present?
      @uid = @data[:id] ||= @data[:sub]
      @data
    end

    def formatted_user_data
      {
        username:         @data['username'],
        image_url:        @data['image_url'],
        provider:         'instagram',
        token:            @access_token,
        email:            @data['email'],
        uid:              @data['id'],
        display_name:     @data['username']
      }
    end
  end
end
