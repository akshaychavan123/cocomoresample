# This migration comes from bx_block_catalogue (originally 20210507093054)
class CreateCustomerFeedbacks < ActiveRecord::Migration[6.0]
  def change
    create_table :customer_feedbacks do |t|
      t.string :title
      t.text :description
      t.integer :position
      t.string :customer_name
      t.integer :catalogue_id
      t.boolean :is_active
      t.timestamps
    end
  end
end
