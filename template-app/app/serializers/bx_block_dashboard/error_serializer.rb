module BxBlockDashboard
  class ErrorSerializer < BuilderBase::BaseSerializer
    attribute :errors do |coupon|
      coupon.errors.as_json
    end
  end
end
