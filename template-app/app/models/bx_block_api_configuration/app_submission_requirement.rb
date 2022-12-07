module BxBlockApiConfiguration
  class AppSubmissionRequirement < ApplicationRecord
    attr_accessor :json_attached

    self.table_name = :app_store_requirements
    has_many :app_categories, foreign_key: :app_store_requirement_id

    has_one_attached :app_icon
    has_one_attached :common_feature_banner

    has_one_attached :json_file

    accepts_nested_attributes_for :app_categories, allow_destroy: true

    validates :app_name, presence: true
    validates :short_description, presence: true
    validates :description, presence: true
    validates_presence_of :first_name, :last_name, :email, :address, :city, :state, :postal_code, :country_name

    validates_length_of :app_name, maximum: 30
    validates_length_of :short_description, maximum: 80
    validates_length_of :description, maximum: 4000

    after_commit :upload_json

    validate :app_icon_field
    validates :common_feature_banner, content_type: ['image/png', 'image/jpg', 'image/jpeg'], dimension: { width: 1024, height: 500, message: 'Common feature banner can be only of 1024*500' }

    validate :check_default_price
    validate :check_auto_price_conversion

    TARGET_AUDIENCE = ['5 and under', '6-8', '9-12', '13-15', '16-17', '18 and over']

    def app_icon_field
      change = self.attachment_changes['app_icon']
      return true if change.blank?
      file = change.attachable
      metadata = ActiveStorageValidations::Metadata.new(file).metadata

      return true if metadata[:width].to_i == 512 && metadata[:height].to_i == 512
      return true if metadata[:width].to_i == 1024 && metadata[:height].to_i == 1024

      self.errors.add(:app_icon, "Appicon can be only of 512*512 or 1024*1024")
      return false
    end

    def check_default_price
      if self.is_paid == false && self.default_price.present?
        self.errors.add(:default_price, "Default price is applicable for paid app.")
      elsif self.is_paid && !self.default_price.present?
        self.errors.add(:default_price, "Default price is mandatory for paid app.")
      end
    end

    def check_auto_price_conversion
      if self.is_paid == false && self.auto_price_conversion.present?
        self.errors.add(:default_price, "Auto price conversion is applicable for paid app.")
      elsif self.is_paid && !self.auto_price_conversion.present?
        self.errors.add(:default_price, "Auto price conversion is mandatory for paid app.")
      end
    end

    def get_json_response
      get_app_categories
      response =  {
        app_name: self.app_name,
        short_description: self.short_description,
        description: self.description,
        app_icon: self.app_icon_url.present? ? self.app_icon_url[:url] : ' ',
        common_feature_banner: self.common_feature_banner_url.present? ? self.common_feature_banner_url[:url] : ' ',
        android_app_categorization:{
          product_details: {
              title: @android_app&.product_title,
              promotional_text: self.short_description,
              full_description: self.description
          },
          graphic_assets: {
              app_screen_shots: @android_app&.get_screen_shots_url,
              app_icon: self.app_icon_url.present? ? self.app_icon_url[:url] : ' '
          },
          categorization_of_app: {
            category: @android_app&.app_category
          },
          keywords: self.tags,

          contact_details: {
              website: self.website,
              email: self.email,
              phone: self.phone,
              first_name: self.first_name,
              last_name: self.last_name,
              address: self.address,
              city: self.city,
              state: self.state,
              postal_code: self.postal_code,
              country: self.country_name
          },
          page_urls:{
              privacy_policy_url: self.privacy_policy_url,
              support_url: self.support_url,
              marketing_url: self.marketing_url
          },
          price_and_distribution: {
              copyright: self.copyright,
              paid: self.is_paid,
              countries: self.distributed_countries,
              app_review_information: {
                  username: @android_app&.review_username,
                  password: @android_app&.review_password,
                  notes: @android_app&.review_password
              }
          }
          },
        ios_app_categorization:{
          product_details: {
              title: @ios_app&.product_title,
              short_description: self.short_description,
              full_description: self.description
          },
          graphic_assets: {
              app_screen_shots: @ios_app&.get_screen_shots_url,
              app_icon: self.app_icon_url.present? ? self.app_icon_url[:url] : ' ',
              feature_graphic: @ios_app&.feature_graphic_url
          },
          categorization_of_app: {
              application_type: @ios_app&.app_category,
              category: @ios_app&.app_category
          },
          contact_details: {
              website: self.website,
              email: self.email,
              phone: self.phone
          },
          tnc_and_privacy_policy: {
              privacy_policy_url: self.privacy_policy_url,
              terms_and_conditions_url: self.terms_and_conditions_url
          },
          price_and_distribution: {
              paid: self.is_paid,
              default_price: self.default_price,
              auto_price_conversion: self.auto_price_conversion,
              distribute_in_this_coutry: self.distributed_countries,
              android_wear: self.android_wear,
              google_play_for_education: self.google_play_for_education,
              content_guidlines: self.content_guidlines,
              us_export_laws: self.us_export_laws,
              target_audience_and_content: self.target_audience_and_content,
              tags: self.tags
          }
          },
        keywords: self.tags,
        contact_details: {
            website: self.website,
            email: self.email,
            phone: self.phone,
            first_name: self.first_name,
            last_name: self.last_name,
            address: {
                city: self.city,
                state: self.state,
                postal_code: self.postal_code,
                country: self.country_name
            }
        },
        page_urls: {
            privacy_policy_url: self.privacy_policy_url,
            support_url: self.support_url,
            marketing_url: self.marketing_url,
            terms_and_conditions_url: self.terms_and_conditions_url
        },
        target_audience_and_content: self.target_audience_and_content,
        pricing_and_distribution:{
          is_paid: self.is_paid,
          default_price: self.default_price,
          distributed_countries: self.distributed_countries,
          auto_price_conversion: self.auto_price_conversion,
          android_wear: self.android_wear,
          google_play_for_education: self.google_play_for_education,
          content_guidlines: self.content_guidlines,
          us_export_laws: self.us_export_laws,
          copyright: self.copyright
        }

      }
    end

    def get_app_categories
      @android_app = self.app_categories.where(app_type: 'android').last
      @ios_app = self.app_categories.where(app_type: 'ios').last
    end

    def common_feature_banner_url
      return if self.common_feature_banner.blank?

      {id: self.common_feature_banner.id, url: url_for(self.common_feature_banner)} if ENV['HOST_URL'].present?
    end

    def app_icon_url
      return if self.app_icon.blank?

      {id: self.app_icon.id, url: url_for(self.app_icon)} if ENV['HOST_URL'].present?
    end

    def upload_json
      unless self.json_attached
        data = self.get_json_response
        data = data.to_json( include: { categories: { include: { my_cases: { include: [{ questions: { include: :answers } }, :keys ] } } } } )
        temp_file = Tempfile.new("temp_json")
        temp_file.write(data)
        temp_file.rewind
        self.json_attached = true
        self.json_file.attach(io: temp_file, filename: "store_requirements.json", content_type: "application/json")
      end
    end

    def json_file_service_url
      if self.json_file.attached?
        if Rails.env.eql?('development')
          Rails.application.routes.url_helpers.url_for(self.json_file)
        else
          self.json_file.service.send(:object_for, self.json_file.key).public_url
        end
      end
    end
  end
end
