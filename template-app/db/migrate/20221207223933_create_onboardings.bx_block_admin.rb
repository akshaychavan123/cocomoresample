# This migration comes from bx_block_admin (originally 20211215051539)
class CreateOnboardings < ActiveRecord::Migration[6.0]
  def change
    create_table :onboardings do |t|
      t.string :title
      t.string :description

      t.timestamps
    end

    add_reference :onboarding_steps, :onboarding, foreign_key: :true
  end
end
