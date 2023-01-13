class ApplicationController < ActionController::Base
  protect_from_forgery unless: -> { request.format.json? }
  before_action :set_host_url

  def page_not_found
    respond_to do |format|
      format.html { render template: 'errors/not_found_error', layout: 'layouts/application', status: 404 }
      format.all  { render nothing: true, status: 404 }
    end
  end

  def server_error
    respond_to do |format|
      format.html { render template: 'errors/internal_server_error', layout: 'layouts/error', status: 500 }
      format.all  { render nothing: true, status: 500}
    end
  end

  def set_host_url
    $hostname ||= request.base_url
  end

  def url_for(file)
    if file.class.name.include?('ActiveStorage') && file.respond_to?(:key)
      url = ENV['MINIO_CDN_ENDPOINT'].present? ? ENV['MINIO_CDN_ENDPOINT'] : Rails.configuration.x.cdn_host
      "#{url}/#{file.key}"
    end
  end
end
