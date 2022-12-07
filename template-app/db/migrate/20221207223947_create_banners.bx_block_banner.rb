# This migration comes from bx_block_banner (originally 20210304052448)
class CreateBanners < ActiveRecord::Migration[6.0]
  def change
    create_table :banners do |t|
      t.string :name

      t.timestamps
    end
  end
end
