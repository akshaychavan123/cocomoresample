module UrlUtilities
  extend ActiveSupport::Concern

  def url_for(file)
    base_url + Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true)
  end

  def base_url
    'https://' + (ENV['HOST_URL'] || ENV['BASE_URL'] || 'http://localhost:3000')
  end
end
