module BxBlockSocialMediaAccount
  class SocialAuth < BxBlockSocialMediaAccount::ApplicationRecord
    self.table_name = 'social_auths'

    belongs_to :account, class_name: "AccountBlock::Account"
    validates_presence_of :account_id, :uid, :provider
    validates_uniqueness_of :uid, scope: :provider

    def self.create_from_provider_data(provider_data)
      auth = find_by(uid: provider_data["unique_auth_id"],provider: provider_data["provider"], account_id:provider_data["account_id"])
      unless auth
        self.new do |auth|
          auth.provider = provider_data["provider"]
          auth.uid = provider_data["unique_auth_id"]
          auth.account_id = provider_data["account_id"]
          auth.secret = provider_data["secret"]
          auth.display_name = provider_data["display_name"]
          auth.save!
        end
      else
        unless auth.display_name == provider_data["display_name"]
          auth.display_name = provider_data["display_name"]
          auth.save!
          auth
        else
          auth
        end
      end
    end
  end
end
