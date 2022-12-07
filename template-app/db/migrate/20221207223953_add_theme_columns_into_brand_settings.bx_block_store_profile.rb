# This migration comes from bx_block_store_profile (originally 20210402060148)
class AddThemeColumnsIntoBrandSettings < ActiveRecord::Migration[6.0]
  def change
    add_column :brand_settings, :is_facebook_login, :boolean
    add_column :brand_settings, :is_google_login, :boolean
    add_column :brand_settings, :is_apple_login, :boolean
    add_column :brand_settings, :transparent_color, :string
    add_column :brand_settings, :grey_color, :string
    add_column :brand_settings, :black_color, :string
    add_column :brand_settings, :white_color, :string
    add_column :brand_settings, :primary_color, :string
    add_column :brand_settings, :background_grey_color, :string
    add_column :brand_settings, :extra_button_color, :string
    add_column :brand_settings, :header_text_color, :string
    add_column :brand_settings, :header_subtext_color, :string
    add_column :brand_settings, :background_color, :string
    add_column :brand_settings, :secondary_color, :string
    add_column :brand_settings, :secondary_button_color, :string
  end
end
