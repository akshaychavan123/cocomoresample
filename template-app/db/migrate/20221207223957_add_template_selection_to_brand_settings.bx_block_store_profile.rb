# This migration comes from bx_block_store_profile (originally 20220419104625)
class AddTemplateSelectionToBrandSettings < ActiveRecord::Migration[6.0]
  def change
    add_column :brand_settings, :template_selection, :string, default: 'Minimal'
    add_column :brand_settings, :color_palet, :string, default: "{themeName: 'Sky',primaryColor:'#364F6B',secondaryColor:'#3FC1CB'}"
  end
end
