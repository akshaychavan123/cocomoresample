# frozen_string_literal: true

module BxBlockShippingCharge
  class Error < BxBlockShippingCharge::Base
    def success?
      false
    end

    def on_error
      yield(@data, @message, @status)
      self
    end

    def on_success
      self
    end
  end
end
