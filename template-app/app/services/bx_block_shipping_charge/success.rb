# frozen_string_literal: true
module BxBlockShippingCharge
  class Success < BxBlockShippingCharge::Base
    def success?
      true
    end

    def on_success
      yield(@data, @message, @status)
      self
    end

    def on_error
      self
    end
  end
end
