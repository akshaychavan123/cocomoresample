# This migration comes from bx_block_api_configuration (originally 20210719094207)
class ChangeContentGuidlineToBool < ActiveRecord::Migration[6.0]
  def change
    remove_column :app_store_requirements, :content_guidlines
    add_column :app_store_requirements, :content_guidlines, :boolean, default: true
  end
end
