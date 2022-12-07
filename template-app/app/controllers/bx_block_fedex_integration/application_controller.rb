module BxBlockFedexIntegration
  class ApplicationController < BuilderBase::ApplicationController
    protect_from_forgery unless: -> { request.format.json? }
  end
end
