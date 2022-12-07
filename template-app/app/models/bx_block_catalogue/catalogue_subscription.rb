module BxBlockCatalogue
  class CatalogueSubscription < BxBlockCatalogue::ApplicationRecord
    self.table_name = :catalogue_subscriptions
    belongs_to :catalogue

    #validations
    validates :subscription_period, :subscription_package, presence: true
    validate :check_unique_subscription

    #constants
    SUBSCRIPTION_PACKAGE = ['daily', 'weekly',  'monthly']

    SUBSCRIPTION_PERIOD = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12']

    MORNING_SLOTS = ['6am_to_9am', '9am_to_12pm']
    EVENING_SLOTS = ['3pm_to_6pm', '6pm_to_9pm']

    def check_unique_subscription
      existing_subscriptions = self.catalogue.catalogue_subscriptions.where.not(id: nil)
      existing_subscriptions.each do |existing_subscription|
        existing_combination = []
        new_combination = []
        existing_combination << existing_subscription.subscription_package
        existing_combination << existing_subscription.subscription_period
        existing_combination << existing_subscription.morning_slot
        existing_combination << existing_subscription.evening_slot
        existing_combination << existing_subscription.discount
        new_combination << self.subscription_package
        new_combination << self.subscription_period
        new_combination << self.morning_slot
        new_combination << self.evening_slot
        new_combination << self.discount
        if existing_combination == new_combination
          errors.add(:subscription_period, "is alreay been taken.")
          break
        end
      end
    end

  end
end
