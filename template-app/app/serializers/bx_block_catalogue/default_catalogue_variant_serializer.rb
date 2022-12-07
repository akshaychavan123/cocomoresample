module BxBlockCatalogue
  class DefaultCatalogueVariantSerializer < BuilderBase::BaseSerializer
    attributes :id, :catalogue_id, :stock_qty, :on_sale, :variant_property_id,
               :price_including_tax, :is_default
  end
end
