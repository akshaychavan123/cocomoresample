# This migration comes from bx_block_catalogue (originally 20210908104802)
class RemoveTableColorSize < ActiveRecord::Migration[6.0]
  def change
    drop_table :catalogue_variant_colors
    drop_table :catalogue_variant_sizes
  end
end
