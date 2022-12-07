# This migration comes from bx_block_interactive_faqs (originally 20201002070211)
class CreateInteractiveFaqs < ActiveRecord::Migration[6.0]
  def change
    create_table :interactive_faqs do |t|
      t.string :title
      t.text :content

      t.timestamps
    end
  end
end
