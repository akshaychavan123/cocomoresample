module BxBlockCatalogue
  class VariantSerializer < BuilderBase::BaseSerializer
    attributes :id, :name

    attribute :variant_property do |object|
      object.variant_properties
    end
  end
end
