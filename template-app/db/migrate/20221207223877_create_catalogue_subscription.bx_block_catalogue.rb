# This migration comes from bx_block_catalogue (originally 20210818071913)
class CreateCatalogueSubscription < ActiveRecord::Migration[6.0]
  def change
    create_table :catalogue_subscriptions do |t|
      t.string :subscription_package
      t.string :subscription_period
      t.decimal :discount
      t.bigint :catalogue_id
      t.string :morning_slot
      t.string :evening_slot
      t.string :subscription_number
    end
  end
end
