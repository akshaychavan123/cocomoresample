module BxBlockCatalogue
  class Variant < BxBlockCatalogue::ApplicationRecord
    self.table_name = :variants

    #associations
    has_many :variant_properties , dependent: :destroy
    accepts_nested_attributes_for :variant_properties, allow_destroy: true, reject_if: :all_blank
    has_many :images, :as => :imageable

    #scopes
    scope :select_variant, -> (catalogue_variant) { where.not(id: catalogue_variant&.catalogue_variant_properties.map(&:variant_id)) }

    #validation
    validates_presence_of :name
    validate :has_variant_properties

    after_commit :update_onboarding_step

    def has_variant_properties
      errors.add(:base, 'must add at least one property') if self.variant_properties.blank?
    end

    private

    def update_onboarding_step
      step_update_service = BxBlockAdmin::UpdateStepCompletion.new('variants', self.class.to_s)
      step_update_service.call
    end
  end
end
