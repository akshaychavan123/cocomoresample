module BxBlockBanner
  class BannerSerializer < BuilderBase::BaseSerializer

    attributes :id, :banner_position, :created_at, :updated_at
    attribute :images do |object, params|
      if object.attachments.present?
        BxBlockFileUpload::AttachmentSerializer.new(object.attachments.order(:position), { params: params })
      end
    end
  end
end
