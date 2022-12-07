module BxBlockCatalogue
  class CatalogueSubscriptionSerializer < BuilderBase::BaseSerializer
    attributes :id, :catalogue_id, :subscription_package, :subscription_period, :discount, :morning_slot, :evening_slot, :subscription_number

    attribute :subscription_period do |object|
      "#{object.subscription_period} month"
    end

    attribute :morning_slot do |object|
      object.morning_slot.humanize.capitalize if object.morning_slot.present?
    end

    attribute :evening_slot do |object|
      object.evening_slot.humanize.capitalize if object.evening_slot.present?
    end
  end
end
