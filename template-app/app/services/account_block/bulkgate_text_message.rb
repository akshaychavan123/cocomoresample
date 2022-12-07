module AccountBlock
  class BulkgateTextMessage

    require 'net/http'

    def initialize(full_phone_number, text_content)
      @full_phone_number = full_phone_number
      @text_content = text_content
    end

    def call
      uri = URI.parse(auth_url)
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri)
      http.use_ssl = true
      request.set_form_data(json_data)
      response = http.request(request)
    end

    private

    def auth_url
      "https://portal.bulkgate.com/api/1.0/simple/transactional"
    end

    def json_data
      {
        "application_id": ENV['APPLICATION_ID'],
        "application_token": ENV['APPLICATION_TOKEN'],
        "number": @full_phone_number,
        "text": @text_content,
        "country": "in"
      }
    end
  end
end
