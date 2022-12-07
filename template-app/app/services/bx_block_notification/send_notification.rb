module BxBlockNotification
  class SendNotification
    FCM_SERVER_KEY = BxBlockStoreProfile::BrandSetting.last&.api_key
    attr_accessor :message, :title, :fcm_client, :data

    def initialize(notification = "",message = "", title = "", account = "", data_value = "")
      @notification = notification
      @message = notification.present? ? notification.message : message
      @title = notification.present? ? notification.title : title
      @registration_id = notification.present? ? notification.account.fcm_token : account.fcm_token
      @fcm_client = FCM.new(FCM_SERVER_KEY)
      @data = data_value.present? ? data_value : data || {}
    end

    def call
      if @registration_id.present?
        options = { "notification": {"title": title, "body": message}, data: data}
        response = fcm_client.send(@registration_id, options)
      end
    end

    private

    def data
      if @notification.present? && @notification.source == 'Order'
        { order_id: @notification.source_id, notification_key: @notification.message }
      else
        {}
      end
    end
  end
end
