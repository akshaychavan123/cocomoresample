# This migration comes from bx_block_api_configuration (originally 20210621060606)
class CreateAppStoreRequirements < ActiveRecord::Migration[6.0]
  def change
    create_table :app_store_requirements do |t|
      t.string :app_name
      t.string :short_description
      t.string :description
      t.string :distributed_countries
      t.string :content_guidlines
      t.string :copyright
      t.string :tags, array: true, default: []
      t.string :website
      t.string :email
      t.string :first_name
      t.string :last_name
      t.string :address
      t.string :city
      t.string :state
      t.string :postal_code
      t.string :country_name
      t.string :privacy_policy_url
      t.string :support_url
      t.string :marketing_url
      t.string :terms_and_conditions_url
      t.boolean :is_paid
      t.integer :default_price
      t.boolean :auto_price_conversion
      t.boolean :android_wear
      t.boolean :google_play_for_education
      t.boolean :us_export_laws
      t.string :target_audience_and_content
      t.string :phone
      t.timestamps
    end
  end
end
