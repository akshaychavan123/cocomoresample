# This migration comes from bx_block_admin (originally 20211215051541)
class AddStepCompletionToOnboardingSteps < ActiveRecord::Migration[6.0]
  def change
    add_column :onboarding_steps, :step_completion, :jsonb
  end
end
