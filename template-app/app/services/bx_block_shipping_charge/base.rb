# frozen_string_literal: true

module BxBlockShippingCharge
  class Base
    attr_reader :data, :message, :status
    def initialize(data = nil, message = nil, status = nil)
      @data = data
      @message = message
      @status = status
    end
  end
end
