# This migration comes from bx_block_store_profile (originally 20210324052234)
class CreateBrandSettings < ActiveRecord::Migration[6.0]
  def change
    create_table :brand_settings do |t|
      t.string :heading
      t.string :sub_heading
      t.string :header_color
      t.string :common_button_color
      t.string :button_hover_color
      t.string :brand_text_color
      t.string :active_tab_color
      t.string :inactive_tab_color
      t.string :active_text_color
      t.string :inactive_text_color
      t.integer :country
      t.integer :currency_type
      t.string :phone_number
      t.string :fb_link
      t.string :instagram_link
      t.string :twitter_link
      t.string :youtube_link
      t.timestamps
    end
  end
end
