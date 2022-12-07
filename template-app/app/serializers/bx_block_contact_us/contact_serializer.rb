# == Schema Information
#
# Table name: contacts
#
#  id           :bigint           not null, primary key
#  account_id   :bigint
#  name         :string
#  email        :string
#  phone_number :string
#  description  :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
module BxBlockContactUs
  class ContactSerializer < BuilderBase::BaseSerializer
    attributes *[
      :name,
      :email,
      :phone_number,
      :description,
      :created_at,
      :purpose_of_contact,
    ]

    attribute :user do |object|
      user_for object
    end

    class << self
      private

      def user_for(object)
        if object.account.present?
          "#{object.account.first_name} #{object.account.last_name}"
        end
      end
    end
  end
end
