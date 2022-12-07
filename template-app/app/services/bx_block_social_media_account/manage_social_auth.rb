module BxBlockSocialMediaAccount
  class ManageSocialAuth
  attr_accessor :params, :social_auth

    def initialize(params)
      @params = params
      @social_auth = BxBlockSocialMediaAccount::SocialAuth.find_or_initialize_by(provider: @params[:provider], uid: @params[:uid])
    end

    def call
      user_obj = user_attr
      social_auth_obj = social_auth_attr
      social_auth_obj.account_id ||= user_obj.id
      social_auth.display_name = params[:display_name] if params[:display_name].present?
      social_auth_obj.save
      user_obj
    end

     private

    def user_attr
      user = initialize_user
      if params[:first_name].present? || params[:last_name].present?
        user.full_name = "#{first_name} #{last_name}" if user.full_name.blank?
      else
        user.full_name = params[:username] if user.full_name.blank?
      end
      user.password = SecureRandom.urlsafe_base64.to_s if user.password_digest.blank?
      # user.image = params[:image_url] unless user.image.attached?
      unless user.image.attached?
        if params[:image_url].present?
          url = URI.parse(params[:image_url])
          filename = File.basename(url.path)
          file = URI.open(url)
          user.image.attach(io: file, filename: filename)
        end
      end
      user.provider = params[:provider].present? ? params[:provider] : ''
      user.first_name = params[:first_name].present? ? params[:first_name] : ''

      user.last_name = params[:last_name].present? ? params[:last_name] : ''

      user.full_name = params[:name].present? ? params[:name] : params['email'].split('@')[0] if params[:provider] == 'apple'
      # user.uuid = params["uuid"] if params["uuid"].present?
      user.activated = true
      user.save
      user
    end

    def initialize_user
      user = if social_auth.persisted?
               social_auth.account
             else
               user = if params[:email].present?
                        AccountBlock::EmailAccount.find_or_initialize_by(email: params[:email])
                      else
                        AccountBlock::EmailAccount.new
                      end
             end
    end

    def social_auth_attr
      social_auth.secret = params[:secret]
      social_auth.token  = params[:token]
      social_auth
    end

    def fallback_name
      params["name"]&.split(' ')
    end

    def fallback_first_name
      fallback_name.try(:first)
    end

    def fallback_last_name
      fallback_name.try(:last)
    end

    def first_name
      first_name ||= (params[:first_name] || fallback_first_name)
    end

    def last_name
      last_name ||= (params[:last_name] || fallback_last_name)
    end
  end
end
