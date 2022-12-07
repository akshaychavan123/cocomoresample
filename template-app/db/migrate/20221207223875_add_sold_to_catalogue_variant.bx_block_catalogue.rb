# This migration comes from bx_block_catalogue (originally 20210419084746)
class AddSoldToCatalogueVariant < ActiveRecord::Migration[6.0]
  def change
    add_column :catalogue_variants, :sold, :integer
    add_column :catalogue_variants, :current_availability, :integer
    add_column :catalogue_variants, :remaining_stock, :integer
    change_column :catalogue_variants, :on_sale, :boolean, default: false
  end
end
