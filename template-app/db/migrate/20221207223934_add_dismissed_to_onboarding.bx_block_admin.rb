# This migration comes from bx_block_admin (originally 20211215051540)
class AddDismissedToOnboarding < ActiveRecord::Migration[6.0]
  def change
    add_column :onboardings, :dismissed, :boolean, default: false, null: false
  end
end
