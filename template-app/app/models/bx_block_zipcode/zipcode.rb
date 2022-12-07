module BxBlockZipcode
  class Zipcode < BxBlockZipcode::ApplicationRecord
    self.table_name = :zipcodes

    validates_presence_of :code, :charge, :price_less_than
    validates_uniqueness_of :code

    scope :activated, -> { where(activated: true) }

    after_create :track_event

    def track_event
      Analytics.track(user_id: ENV["HOST_URL"].split("-")[1],event: 'New Zipcodes & Shipping Charges Created')
    end
  end
end
