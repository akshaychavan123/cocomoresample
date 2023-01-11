module BxBlockStoreProfile
  class BrandSetting < BxBlockStoreProfile::ApplicationRecord
    include UrlUtilities
    self.table_name = :brand_settings
    has_one_attached :logo
    has_one_attached :promotion_banner

    attr_accessor :web_json_attached, :mobile_json_attached, :cropped_image

    has_one_attached :web_json_file
    has_one_attached :mobile_json_file

    after_commit :upload_json
    after_commit :update_onboarding_step
    after_commit :check_api_configuration, if: :saved_change_to_country?
    after_commit :check_shipping_configuration, if: :saved_change_to_country?

    belongs_to :address_state, class_name: "BxBlockOrderManagement::AddressState", optional: true

    validates_presence_of :address_state_id, if: :country_india?
    validates :logo, :country, presence: true
    validates_length_of :heading, maximum: 50
    validate :validate_phone_number
    validate :validate_whatsapp_number

    enum country: ['india', 'uk']

    def cropped_image=(val)
      @cropped_image = val
      return if val.blank?

      decoded_data = val.split(",")[1]
      image_extention = val.split(',').first.gsub("\;base64", "").gsub("data:image/", '') rescue 'png'
      image_path="tmp/cropped_image." + image_extention
      File.open(image_path, 'wb') do |f|
        f.write(Base64.decode64(decoded_data))
      end
      self.logo.attach(io: File.open(image_path),filename: image_path.split('/')[1])
      File.delete(image_path) if File.exist?(image_path)
    end

    def upload_json
      unless self.web_json_attached
        data = self.nested_response_hash
        data = data.to_json( include: { categories: { include: { my_cases: { include: [{ questions: { include: :answers } }, :keys ] } } } } )
        temp_file = Tempfile.new("temp_json")
        temp_file.write(data)
        temp_file.rewind
        self.web_json_attached = true
        self.web_json_file.attach(io: temp_file, filename: "web_json.json", content_type: "application/json")
        temp_file.close
      end

      unless self.mobile_json_attached
        data = self.simple_response_hash
        data = data.to_json( include: { categories: { include: { my_cases: { include: [{ questions: { include: :answers } }, :keys ] } } } } )
        mobile_temp_file = Tempfile.new("temp_json")
        mobile_temp_file.write(data)
        mobile_temp_file.rewind
        self.mobile_json_attached = true
        self.mobile_json_file.attach(io: mobile_temp_file, filename: "web_json.json", content_type: "application/json")
        mobile_temp_file.close
      end
    end

    def web_json_file_service_url
      if self.web_json_file.attached?
        if Rails.env.eql?('development')
          Rails.application.routes.url_helpers.url_for(self.web_json_file)
        else
          self.web_json_file.service.send(:object_for, self.web_json_file.key).public_url
        end
      end
    end

    def mobile_json_file_service_url
      if self.mobile_json_file.attached?
        if Rails.env.eql?('development')
          Rails.application.routes.url_helpers.url_for(self.mobile_json_file)
        else
          self.mobile_json_file.service.send(:object_for, self.mobile_json_file.key).public_url
        end
      end
    end

    def full_image_url(image, style = 'original')
      s3_expiring_url(image, style)
    end

    def s3_expiring_url(image, style)
      return image.url(style) if Rails.env.development?
      image.expiring_url(nil, style)
    end

    def logo_url
      return if self.logo.blank?

      {id: self.logo.id, url: url_for(logo)} if ENV['HOST_URL'].present?
    end

    def promotion_banner_url
      return if self.promotion_banner.blank?

      {id: self.promotion_banner.id, url: url_for(promotion_banner)} if ENV['HOST_URL'].present?
    end

    def simple_response_hash
      get_configurations
      response = {
        attributes: {
          heading: self.heading,
          sub_heading: self.sub_heading,
          phone_number: self.phone_number,
          fb_link: self.fb_link,
          instagram_link: self.instagram_link,
          twitter_link: self.twitter_link,
          youtube_link: self.youtube_link,
          primary_color: self.primary_color,
          highlight_primary_color: self.highlight_primary_color,
          highlight_secondary_color: self.highlight_secondary_color,
          background_color: "#ffffff",
          background_grey: "#3e454f",
          border_color: "#a9a9a9",
          common_button_color: self.common_button_color,
          secondary_color: "#e65e52",
          secondary_button_color: "#e65e52",
          extra_button_color: "#080808",
          header_color: "#ffffff",
          header_text_color: "#ffffff",
          header_subtext_color: "#ffffff",
          white: "#fff",
          black: "#000",
          grey: "#f2f2f2",
          transparent: "rgba(34,34,34, 0.8)",
          country: self.country,
          country_code: self.country == "uk" ? 44 : 91,
          currency_type: self.currency_type,
          isFacebookLogin: self.is_facebook_login,
          isGoogleLogin: self.is_google_login,
          isAppleLogin: self.is_apple_login,
          razorpay: {api_key: ENV['RAZORPAY_KEY']||@razorpay_configuration&.api_key, secret_key:ENV['RAZORPAY_SECRET']||@razorpay_configuration&.api_secret_key,
          account_id: ENV['RAZORPAY_PARTNER_ACCOUNT_ID'] },
          stripe: {stripe_pub_key: @stripe_configuration&.api_key, stripe_secret_key: @stripe_configuration&.api_secret_key },
          logo: self.logo_url.present? ? self.logo_url[:url] : '' ,
          firebase:{
            apiKey: self.api_key, authDomain: self.auth_domain, databaseURL: self.database_url, projectId: self.project_id, storageBucket: self.storage_bucket, messagingSenderId: self.messaging_sender_id ,appId: self.app_id, measurementId: self.measurement_id}
          }
        }
      if country_india?
        response[:ShippingKeys] = {
          shiprocket: {
            ship_rocket_base_url: @shiprocket_configuration&.ship_rocket_base_url, ship_rocket_user_email: @shiprocket_configuration&.ship_rocket_user_email, ship_rocket_user_password: @shiprocket_configuration&.ship_rocket_user_password
          }
        }
        response[:PaymentKeys] = {
          razorpay: {
            api_key: ENV['RAZORPAY_KEY']||@razorpay_configuration&.api_key,
            secret_key:ENV['RAZORPAY_SECRET']||@razorpay_configuration&.api_secret_key,
            account_id: ENV['RAZORPAY_PARTNER_ACCOUNT_ID']
          }
        }
      else
        response[:ShippingKeys] = {
          logistics: {
            oauth_site_url: @logistics_configuration&.oauth_site_url,
            base_url: @logistics_configuration&.base_url,
            client_id: @logistics_configuration&.client_id,
            client_secret: @logistics_configuration&.client_id,
            logistic_api_key: @logistics_configuration&.client_id
          }
        }
        response[:PaymentKeys] = {
          stripe: {
            stripe_pub_key: @stripe_configuration&.api_key,
            stripe_secret_key: @stripe_configuration&.api_secret_key
          }
        }
      end
      response
    end

    def nested_response_hash
      get_configurations
      whatsapp_number = if self.country == "india"
        "91" + self.whatsapp_number rescue ""
      else
        "44" + self.whatsapp_number rescue ""
      end
      whatsapp_url = if self.whatsapp_number.present? && self.whatsapp_message.present?
        message = self.whatsapp_message.gsub(' ', '%20')
        "https://wa.me/#{whatsapp_number}?text=#{message}"
      elsif self.whatsapp_number.present?
        "https://wa.me/#{whatsapp_number}"
      else
        ""
      end
      response = {
          buttonsColor: {
              regularButtonColor: self.common_button_color,
              regularTextColor: self.active_text_color,
              hoverButtonColor: self.button_hover_color,
              hoverTextColor: '#fff'
          },
          mainTextsColor: {
              regularColorCode: self.active_text_color,
              activeColorCode: self.active_text_color
          },
          commonBordersColor: '#3e454f',
          highlightPrimaryColor: self.highlight_primary_color,
          highlightSecondaryColor: self.highlight_secondary_color,
          commonTextsContent: {
              callUs: self.phone_number
          },
          footerContent: {
              copyright: self.copyright_message,
              facebookSrc: self.fb_link,
              instagramSrc: self.instagram_link,
              twitterSrc: self.twitter_link,
              youtubeSrc: self.youtube_link,
              promotionBannerSrc: self.promotion_banner_url.present? ? self.promotion_banner_url[:url] : ' '
          },
          commonLogoSrc: self.logo_url.present? ? self.logo_url[:url] : '' ,
          productFilterSliderColor: self.sidebar_bg_color,
          PaymentKeys: {
              razorpay: {api_key: ENV['RAZORPAY_KEY']|| @razorpay_configuration&.api_key, secret_key:ENV['RAZORPAY_SECRET']|| @razorpay_configuration&.api_secret_key,
                account_id: ENV['RAZORPAY_PARTNER_ACCOUNT_ID']},
              stripe: {stripe_pub_key: @stripe_configuration&.api_key, stripe_secret_key: @stripe_configuration&.api_secret_key }
          },
          NotificationKeys: {
              firebase:{
                  apiKey: self.api_key, authDomain: self.auth_domain, databaseURL: self.database_url, projectId: self.project_id, storageBucket: self.storage_bucket, messagingSenderId: self.messaging_sender_id ,appId: self.app_id, measurementId: self.measurement_id
              }
          },
          productCarousel: ['Top Picks','On Sale','Recommended Products'],
          ExtraFields: {is_facebook_login: self.is_facebook_login, is_google_login: self.is_google_login, is_apple_login: self.is_apple_login ,country: self.country, country_code: self.country == "uk" ? 44 : 91 ,
                        currency_type: self.currency_type, heading: self.heading, sub_heading: self.sub_heading },
          TemplateSelections: {
            template_selection: self.template_selection,
            color_palet: self.color_palet
          },
          WhatsappIntegration: {
            whatsapp_url: whatsapp_url
          }
      }

      if BxBlockStoreProfile::BrandSetting.last.country == "india"
        response[:ShippingKeys] = {
          shiprocket:
          {
            ship_rocket_base_url: @shiprocket_configuration&.ship_rocket_base_url, ship_rocket_user_email: @shiprocket_configuration&.ship_rocket_user_email, ship_rocket_user_password: @shiprocket_configuration&.ship_rocket_user_password
          }
        }
        response[:PaymentKeys] = {
          razorpay:
          {
            api_key: ENV['RAZORPAY_KEY']||@razorpay_configuration&.api_key,
            secret_key:ENV['RAZORPAY_SECRET']||@razorpay_configuration&.api_secret_key,
            account_id: ENV['RAZORPAY_PARTNER_ACCOUNT_ID']
          }
        }
      else
        response[:ShippingKeys] = {
          logistics: {
            oauth_site_url: @logistics_configuration&.oauth_site_url,
            base_url: @logistics_configuration&.base_url,
            client_id: @logistics_configuration&.client_id,
            client_secret: @logistics_configuration&.client_id,
            logistic_api_key: @logistics_configuration&.client_id
          }
        }
        response[:PaymentKeys] = {
          stripe: {
            stripe_pub_key: @stripe_configuration&.api_key,
            stripe_secret_key: @stripe_configuration&.api_secret_key
          }
        }
      end
      return response
    end

    def get_configurations
      @razorpay_configuration = BxBlockApiConfiguration::ApiConfiguration.find_by(configuration_type: 'razorpay')
      @stripe_configuration = BxBlockApiConfiguration::ApiConfiguration.find_by(configuration_type: 'stripe')
      @logistics_configuration = BxBlockApiConfiguration::ApiConfiguration.find_by(configuration_type: '525k')
      @shiprocket_configuration = BxBlockApiConfiguration::ApiConfiguration.find_by(configuration_type: 'shiprocket')
    end

    def country_india?
      self.country == 'india' ? true : false
    end

    def country_uk?
      self.country == 'uk' ? true : false
    end

    def check_api_configuration
      if self.country_india? && !BxBlockApiConfiguration::ApiConfiguration.find_by(configuration_type: "razorpay").present?
        BxBlockApiConfiguration::ApiConfiguration.create(configuration_type: "razorpay", api_key: "n/a", api_secret_key: "n/a")
      elsif self.country_uk? && !BxBlockApiConfiguration::ApiConfiguration.find_by(configuration_type: "stripe").present?
        BxBlockApiConfiguration::ApiConfiguration.create(configuration_type: "stripe", api_key: "n/a", api_secret_key: "n/a")
      end
    end

    def check_shipping_configuration
      if self.country_india?  && !BxBlockApiConfiguration::ApiConfiguration.find_by(configuration_type: "shiprocket").present?
        BxBlockApiConfiguration::ApiConfiguration.create(configuration_type: "shiprocket", ship_rocket_user_email: "n/a", ship_rocket_user_password: "n/a")
      elsif  self.country_uk?  && !BxBlockApiConfiguration::ApiConfiguration.find_by(configuration_type: "525k").present?
        BxBlockApiConfiguration::ApiConfiguration.create(configuration_type: "525k", oauth_site_url: "n/a", base_url: "n/a", client_id: "n/a", client_secret: "n/a", logistic_api_key: "n/a")
      end
    end


    private

    def update_onboarding_step
      step_update_service = BxBlockAdmin::UpdateStepCompletion.new('branding', self.class.to_s)
      step_update_service.call
    end

    def validate_phone_number
      return if phone_number.blank?
      if country == 'india'
        errors.add(:phone_number, 'must be a 10 digit phone number') unless phone_number =~ /\A\d{10}\z/
      elsif country == 'uk'
        errors.add(:phone_number, 'must be a 11 digit phone number') unless phone_number =~ /\A\d{11}\z/
      end
    end

    def validate_whatsapp_number
      return if whatsapp_number.blank?
      if country == 'india'
        errors.add(:whatsapp_number, 'must be a 10 digit phone number') unless whatsapp_number =~ /\A\d{10}\z/
      elsif country == 'uk'
        errors.add(:whatsapp_number, 'must be a 11 digit phone number') unless whatsapp_number =~ /\A\d{11}\z/
      end
    end
  end
end
