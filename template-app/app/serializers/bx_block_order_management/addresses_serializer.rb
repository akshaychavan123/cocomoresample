module BxBlockOrderManagement
  class AddressesSerializer < BuilderBase::BaseSerializer
    attributes *[
      :id,
      :name,
      :flat_no,
      :address,
      :address_type,
      :address_line_2,
      :zip_code,
      :phone_number,
      :latitude,
      :is_default,
      :city,
      :state,
      :country,
      :account,
      :address_state_id
    ]

    attribute :account, if: Proc.new { |rec, params| params[:user].present? }
  end
end
