# This migration comes from bx_block_banner (originally 20210323043430)
class AddWebBannerToBanner < ActiveRecord::Migration[6.0]
  def change
    add_column :banners, :web_banner, :boolean, default: false
  end
end
