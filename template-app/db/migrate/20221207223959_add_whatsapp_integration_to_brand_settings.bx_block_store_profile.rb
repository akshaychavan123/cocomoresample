# This migration comes from bx_block_store_profile (originally 20220525064655)
class AddWhatsappIntegrationToBrandSettings < ActiveRecord::Migration[6.0]
  def change
    add_column :brand_settings, :whatsapp_number, :string
    # add_column :brand_settings, :is_whatsapp, :boolean, default: false
    add_column :brand_settings, :whatsapp_message, :text
  end
end
