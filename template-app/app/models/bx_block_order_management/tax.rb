module BxBlockOrderManagement
  class Tax < ApplicationRecord
    self.table_name = :taxes
    belongs_to :order, optional: true
    validates :tax_percentage, presence: true

    after_create :track_event
    after_commit :update_onboarding_step

    def track_event
      Analytics.track(user_id: ENV["HOST_URL"].split("-")[1],event: 'New taxes Created')
    end

    private

    def update_onboarding_step
      step_update_service = BxBlockAdmin::UpdateStepCompletion.new('taxes', self.class.to_s)
      step_update_service.call
    end
  end
end
