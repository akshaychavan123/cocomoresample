# This migration comes from bx_block_admin (originally 20211215051538)
class CreateOnboardingSteps < ActiveRecord::Migration[6.0]
  def change
    create_table :onboarding_steps do |t|
      t.string :title
      t.string :description
      t.integer :step

      t.timestamps
    end
  end
end
