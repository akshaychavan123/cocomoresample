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
  class Contact < BxBlockContactUs::ApplicationRecord
    self.table_name = :contacts

    EMAIL_REGEX = /[^@]+[@][\S]+[.][\S]+/.freeze

    belongs_to :account, class_name: "AccountBlock::Account", optional: true

    validates :name, :phone_number, :email, :description, presence: true
    validates :email, :format => { with: EMAIL_REGEX }
    # validate :valid_phone_number, if: Proc.new { |c| c.phone_number.present? }

    def self.filter(query_params)
      ContactFilter.new(self, query_params).call
    end

    private

    def valid_phone_number
      # return if Phonelib.valid?(phone_number)
      # errors.add(:phone_number, 'is not valid')
    end
  end
end
