module ApplicationHelper
  def remote_request(type, path, params={}, target_tag_id)
    "$.#{type}('#{path}',{#{params.collect { |p| "#{p[0]}: #{p[1]}" }.join(", ")}},function(data) {$('##{target_tag_id}').html(data);});"
  end

  def url_for(file)
    if file.class.name.include?('ActiveStorage') && file.respond_to?(:key)
      return super(file) if $hostname.present? && $hostname.include?('localhost')
      url = ENV['MINIO_CDN_ENDPOINT'].present? ? ENV['MINIO_CDN_ENDPOINT'] : Rails.configuration.x.cdn_host
      "#{url}/#{file.key}"
    else
      super
    end
  end
end
