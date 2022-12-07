# This migration comes from bx_block_catalogue (originally 20210929052204)
class RemoveVariantNumberColumn < ActiveRecord::Migration[6.0]
  def change
    remove_column :catalogue_variants, :variant_number, :integer
  end
end
