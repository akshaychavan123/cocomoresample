module BuilderBase
  class BaseSerializer
    include FastJsonapi::ObjectSerializer

    class << self
      def url_for(file)
        if file.class.name.include?('ActiveStorage') && file.respond_to?(:key)
          url = ENV['MINIO_CDN_ENDPOINT'].present? ? ENV['MINIO_CDN_ENDPOINT'] : Rails.configuration.x.cdn_host
          "#{url}/#{file.key}"
        end
      end

      private

      def base_url
        'https://' + (ENV['HOST_URL'] || ENV['BASE_URL'] || 'http://localhost:3000')
      end
    end
  end
end
