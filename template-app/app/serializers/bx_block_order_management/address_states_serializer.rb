module BxBlockOrderManagement
  class AddressStatesSerializer < BuilderBase::BaseSerializer
    attributes *[
      :id,
      :name,
      :gst_code
    ]
  end
end
