module BxBlockHelpCenter
  class HelpCentersController < ApplicationController
    def index
      help_centers = HelpCenter.all
      _help_centers = []
      help_centers.each do |hc|
        hc.description = "<meta name='viewport' content='width=device-width, initial-scale=1'>#{hc.description}"
        _help_centers << hc
      end
      serializer = HelpCenterSerializer.new(_help_centers)
      render :json => serializer.serializable_hash, :status => :ok
    end

    def show_feedback
      feedbacks = BxBlockCatalogue::CustomerFeedback.all.where(is_active: true)
      feedbacks = feedbacks
      _feedbacks = []
      feedbacks.each do |feedback|
        full_image_url = url_for(feedback.image) if feedback.image.present?
        _feedbacks << feedback.attributes.merge({profile_image: full_image_url})
      end
      render json: {
          message: "",
          feedbacks: _feedbacks, status: :ok}
    end
  end
end
