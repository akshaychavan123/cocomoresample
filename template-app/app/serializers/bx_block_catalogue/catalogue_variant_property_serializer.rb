module BxBlockCatalogue
  class CatalogueVariantPropertySerializer < BuilderBase::BaseSerializer
    attributes :id, :catalogue_id, :catalogue_variant_id, :variant_id, :variant_property_id, :created_at, :updated_at

    attribute :variant_name do |object|
      object.variant&.name
    end

    attribute :property_name do |object|
      object.variant_property&.name
    end
  end
end
