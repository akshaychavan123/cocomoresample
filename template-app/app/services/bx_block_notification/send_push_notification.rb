module BxBlockNotification
  class SendPushNotification
    FCM_SERVER_KEY = BxBlockStoreProfile::BrandSetting.last&.api_key
    attr_accessor :message, :title, :fcm_client, :data

    def initialize(notification = "",message = "", title = "", account = "", data_value = "")
      account = AccountBlock::Account.all.pluck(:fcm_token)
      @fcm_client = FCM.new(FCM_SERVER_KEY)
      @notification = notification
      @message = notification.present? ? notification.message : message
      @title = notification.present? ? notification.title : title
      @registration_id = account
    end

    def call
      if @registration_id.present?
        options = { "notification": {"title": title, "body": message} }
        response = fcm_client.send(@registration_id.uniq, options)
      end
    end
  end
end
