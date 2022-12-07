module BxBlockShippingCharge
  class ShippingCharge < BxBlockShippingCharge::ApplicationRecord
    self.table_name = :shipping_charges

    after_commit :update_onboarding_step

    private

    def update_onboarding_step
      step_update_service = BxBlockAdmin::UpdateStepCompletion.new('shipping', self.class.to_s)
      step_update_service.call
    end
  end
end
