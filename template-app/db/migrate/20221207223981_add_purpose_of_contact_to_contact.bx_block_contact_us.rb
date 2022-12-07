# This migration comes from bx_block_contact_us (originally 20210528103413)
class AddPurposeOfContactToContact < ActiveRecord::Migration[6.0]
  def change
    add_column :contacts, :purpose_of_contact, :text
  end
end
