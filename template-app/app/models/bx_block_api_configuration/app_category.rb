module BxBlockApiConfiguration
  class AppCategory < ApplicationRecord
    include UrlUtilities
    self.table_name = :app_categories

    has_many_attached :app_screen_shots
    has_one_attached :feature_graphic

    has_many :attachments, as: :attachable, class_name: "BxBlockFileUpload::Attachment", dependent: :destroy
    accepts_nested_attributes_for :attachments, allow_destroy: true
    belongs_to :app_submission_requirement, foreign_key: :app_store_requirement_id

    APP_TYPE = ['android', 'ios']

    def get_screen_shots_url
      return nil unless self.attachments.present?
      urls = []
      self.attachments.each do |attachment|
        image = {id: attachment.image.id, url: url_for(attachment.image)} if ENV['HOST_URL'].present?
        urls << image[:url]
      end
      return urls
    end

    def feature_graphic_url
      image = {id: self.feature_graphic.id, url: url_for(self.feature_graphic)} if ENV['HOST_URL'].present? && self.feature_graphic.attached?
    end
  end
end
