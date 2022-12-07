# This migration comes from bx_block_store_profile (originally 20220330123834)
class AddHighlightColorsToBrandSettings < ActiveRecord::Migration[6.0]
  def change
    add_column :brand_settings, :highlight_primary_color, :string
    add_column :brand_settings, :highlight_secondary_color, :string
  end
end
