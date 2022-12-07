module BxBlockCatalogue
  class VariantProperty < ApplicationRecord
    self.table_name = :variant_properties
    belongs_to :variant
    has_many :catalogue_variant_properties, dependent: :destroy
    has_many :catalogue_variants , through: :catalogue_variant_properties, dependent: :destroy

    validates :name, presence: true
  end
end
