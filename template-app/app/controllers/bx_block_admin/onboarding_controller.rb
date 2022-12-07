module BxBlockAdmin
  class OnboardingController < ApplicationController
    def dismiss
      onboarding = BxBlockAdmin::Onboarding.first
      if onboarding.present? && onboarding.completed?
        onboarding.update(dismissed: true)
      end
      redirect_to '/'
    end
  end
end
