module BxBlockHelpCenter
  class HelpCenterSerializer < BuilderBase::BaseSerializer
    attributes *[
      :help_center_type,
      :title,
      :description
    ]

    attribute :help_center_type do |object|
      object&.help_center_type.to_s.titleize
    end
  end
end
