# This migration comes from bx_block_catalogue (originally 20210318041340)
class AddColumnInCatalogueVariants < ActiveRecord::Migration[6.0]
  def change
    add_column :catalogue_variants, :is_default, :boolean, default: false
  end
end
