module BxBlockNotification
  class NotificationSerializer < BuilderBase::BaseSerializer
    attributes :id, :source, :source_id, :title, :message, :is_read, :account, :created_at, :updated_at
  end
end
