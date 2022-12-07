module BxBlockBanner
  class Banner < BxBlockBanner::ApplicationRecord
    self.table_name = :banners

    ATTACHMENT_SIZE = {
      web_banner: {
        min_width: 200, max_width: 400, min_height: 375, max_height: 800
      },
      app_banner: {
        min_width: 374, max_width: 400, min_height: 107, max_height: 800
      }
    }

    has_many :attachments, as: :attachable, class_name: "BxBlockFileUpload::Attachment"
    accepts_nested_attributes_for :attachments, allow_destroy: true

    validates :banner_position, :uniqueness => {:scope => :web_banner}, if: -> { banner_position.present? }
    validates :banner_position, presence: true

    attr_accessor :banner
    #after_destroy :update_positions
    after_create :track_event
    after_commit :update_onboarding_step

    def track_event
      if self.web_banner
        Analytics.track(user_id: ENV["HOST_URL"].split("-")[1],event: 'New Web Banner Created')
      else
        Analytics.track(user_id: ENV["HOST_URL"].split("-")[1],event: 'New App Banner Created')
      end
    end

    def update_positions
      banner_position = self.banner_position
      if self.web_banner
        banners = BxBlockBanner::Banner.where("banner_position > ? AND web_banner = ?", banner_position, true)
        if banners.present?
          banners.map do |banner|
            banner.update(banner_position: banner.banner_position - 1)
          end
        end
      else
        banners = BxBlockBanner::Banner.where(web_banner: false)
        if banners.present?
          banners.map do |banner|
            banner.update(banner_position: banner.banner_position - 1) if banner.banner_position > banner_position
          end
        end
      end
    end

    private

    def update_onboarding_step
      step_update_service = BxBlockAdmin::UpdateStepCompletion.new(self.web_banner ? 'web_banner' : 'app_banner', self.class.to_s)
      step_update_service.call
    end
  end
end
