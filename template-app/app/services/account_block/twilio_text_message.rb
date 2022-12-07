module AccountBlock
  class TwilioTextMessage
    attr_reader :message, :to

    def initialize(to, message)
      @to      = to
      @message = message
    end

    def call
      client = Twilio::REST::Client.new
      client.messages.create({
        from: Rails.application.credentials.twilio_phone_number,
        to: @to,
        body: message
      })
    rescue => e
      e.message
    end
  end
end
