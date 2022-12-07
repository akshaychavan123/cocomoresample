module BxBlockSocialMediaAccount
  class SocialAuthSerializer < BuilderBase::BaseSerializer
    attributes *[
      :provider,
      :uid,
      :account_id,
      :display_name
    ]
  end
end
