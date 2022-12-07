module BxBlockCatalogue
  class VariantType < BxBlockCatalogue::ApplicationRecord
    self.table_name = :variant_types

    belongs_to :catalogue_variant

    validates :variant_type, presence: true
    validates :value, presence: true
  end
end
