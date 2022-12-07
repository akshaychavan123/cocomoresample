module BxBlockCatalogue
  class CatalogueVariantProperty < BxBlockCatalogue::ApplicationRecord
    self.table_name = :catalogue_variant_properties

    belongs_to :catalogue
    belongs_to :catalogue_variant
    belongs_to :variant
    belongs_to :variant_property

    before_validation :set_variant
    after_save :delete_self

    validates :variant, uniqueness: { scope: [:catalogue_variant, :catalogue] }

    def set_variant
      self.variant = self.variant_property&.variant
      self.catalogue = self.catalogue_variant&.catalogue
    end

    def delete_self
      if self.variant.blank? && self.variant.blank?
        self.delete
      end
    end
  end
end
