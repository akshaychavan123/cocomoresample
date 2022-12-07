# This migration comes from bx_block_catalogue (originally 20210902070048)
class CreateVariants < ActiveRecord::Migration[6.0]
  def change
    create_table :variants do |t|

      t.string "name"
      t.timestamps
    end
  end
end
