# This migration comes from bx_block_store_profile (originally 20210330070324)
class AddColorsColumnIntoBrandSettings < ActiveRecord::Migration[6.0]
  def change
    add_column :brand_settings, :button_hover_text_color, :string
    add_column :brand_settings, :border_color, :string
    add_column :brand_settings, :sidebar_bg_color, :string
    add_column :brand_settings, :copyright_message, :string
    add_column :brand_settings, :wishlist_icon_color, :string
    add_column :brand_settings, :wishlist_btn_text_color, :string
    add_column :brand_settings, :order_detail_btn_color, :string
  end
end
