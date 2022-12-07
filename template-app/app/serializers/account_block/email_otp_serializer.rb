module AccountBlock
  class EmailOtpSerializer < BuilderBase::BaseSerializer
    attributes :email, :activated, :created_at, :valid_until, :full_name
  end
end
