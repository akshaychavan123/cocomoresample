# == Schema Information
#
# Table name: dashboards
#
#  id         :bigint           not null, primary key
#  title      :string
#  value      :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
module BxBlockDashboard
  class Dashboard < BxBlockDashboard::ApplicationRecord
    self.table_name = :dashboards

    def self.is_website_up?
      begin
        res = fetch_server_url("https://api.cat.builder.ai/v1/project/")
        res['store_front_url']
      rescue
        false
      end
    end

    def self.fetch_server_url_from_hostname
      begin
        if $hostname.include?(".prod.")
          production_server_url
        else
          staging_server_url
        end
      rescue
        "/"
      end
    end

    def self.production_server_url
      begin
        res = fetch_server_url("https://api.cat.builder.ai/v1/project/")
        "https://#{res['store_front_url']}"
      rescue
        "/"
      end
    end

    def self.staging_server_url
      begin
        res = fetch_server_url("https://staging-api.cat.builder.ai/v1/project/")
        "https://#{res['store_front_url']}"
      rescue
        "/"
      end
    end

    private

    def self.fetch_server_url(url)
      project_id = ENV['HOST_URL'].split("-")[1]
      url = URI(url+project_id)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Get.new(url)
      request["cache-control"] = 'no-cache'
      request["postman-token"] = 'a962c155-952b-7833-48fd-30b74557b54c'
      response = http.request(request)
      JSON.parse(response.read_body)
    end
  end
end

