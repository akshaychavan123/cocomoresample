# This migration comes from bx_block_catalogue (originally 20210908050306)
class RemoveCatalogueVariantColorSize < ActiveRecord::Migration[6.0]
  def change
    remove_column :catalogue_variants, :catalogue_variant_color_id
    remove_column :catalogue_variants, :catalogue_variant_size_id
  end
end
