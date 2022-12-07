# This migration comes from bx_block_help_center (originally 20210113102801)
class CreateHelpCenters < ActiveRecord::Migration[6.0]
  def change
    create_table :help_centers do |t|
      t.string :help_center_type
      t.string :title
      t.text :description

      t.timestamps
    end
  end
end
