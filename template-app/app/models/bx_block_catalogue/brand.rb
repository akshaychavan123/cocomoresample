# == Schema Information
#
# Table name: brands
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
module BxBlockCatalogue
  class Brand < BxBlockCatalogue::ApplicationRecord
    self.table_name = :brands

    validates :name, presence: true, uniqueness: true
    after_create :track_event
    after_commit :update_onboarding_step

    def track_event
      Analytics.track(user_id: ENV["HOST_URL"].split("-")[1],event: 'New brands Created')
    end

    private

    def update_onboarding_step
      step_update_service = BxBlockAdmin::UpdateStepCompletion.new('brands', self.class.to_s)
      step_update_service.call
    end
  end
end
