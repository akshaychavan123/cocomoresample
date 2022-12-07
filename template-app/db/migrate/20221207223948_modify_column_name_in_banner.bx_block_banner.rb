# This migration comes from bx_block_banner (originally 20210311133703)
class ModifyColumnNameInBanner < ActiveRecord::Migration[6.0]
  def change
    remove_column :banners, :name
    add_column :banners, :banner_position, :integer
  end
end
