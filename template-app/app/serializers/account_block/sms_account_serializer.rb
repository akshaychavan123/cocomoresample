# == Schema Information
#
# Table name: accounts
#
#  id                :bigint           not null, primary key
#  first_name        :string
#  last_name         :string
#  full_phone_number :string
#  country_code      :integer
#  phone_number      :bigint
#  email             :string
#  activated         :boolean          default(FALSE), not null
#  device_id         :string
#  unique_auth_id    :text
#  password_digest   :string
#  type              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
module AccountBlock
  class SmsAccountSerializer
    include FastJsonapi::ObjectSerializer

    attributes *[
      :full_name,
      :first_name,
      :user_name,
      :last_name,
      :full_phone_number,
      :country_code,
      :phone_number,
      :email,
      :activated,
      :type,
      :created_at,
      :updated_at,
      :device_id,
      :provider,
      :unique_auth_id,
      :guest,
      :uuid,
      :is_notification_enabled,
      :fcm_token
    ]

    attribute :country_code do |object|
      country_code_for object
    end

    attribute :phone_number do |object|
      phone_number_for object
    end

    attribute :image_url do |object|
      if object.image.attached?
        if Rails.env.production?
          url_for(object.image)
        else
          Rails.application.routes.url_helpers.rails_blob_path(object.image, only_path: true)
        end
      end
    end

    attribute :is_social_login do |object|
      object&.social_auths&.present? ? true : false
    end

    attribute :wishlist_quantity do |object|
      object&.wishlist&.wishlist_items&.count
    end

    class << self
      private

      def country_code_for(object)
        return nil unless Phonelib.valid?(object.full_phone_number)
        Phonelib.parse(object.full_phone_number).country_code
      end

      def phone_number_for(object)
        return nil unless Phonelib.valid?(object.full_phone_number)
        Phonelib.parse(object.full_phone_number).raw_national
      end
    end
  end
end
