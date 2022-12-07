# == Schema Information
#
# Table name: onboarding_steps
#
#  id               :bigint           not null, primary key
#  title            :string
#  description      :string
#  step             :integer
#  step_completion  :jsonb
#  onboarding_id    :bigint
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

module BxBlockAdmin
  class OnboardingStepSerializer < BuilderBase::BaseSerializer
    attributes :id, :title, :description, :step, :step_completion, :onboarding_id

    attribute :image_url do |object|
      if object.image.attached?
        if Rails.env.production?
          object.image.service_url
        else
          Rails.application.routes.url_helpers.rails_blob_path(object.image, only_path: true)
        end
      end
    end
  end
end
