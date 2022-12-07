module BxBlockSocialMediaAccount
  module PatchAccountSocialAuthsAssociation
    extend ActiveSupport::Concern

    included do
      has_many :social_auths, class_name: "BxBlockSocialMediaAccount::SocialAuth", dependent: :destroy
    end
  end
end
