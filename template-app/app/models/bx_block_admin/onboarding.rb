module BxBlockAdmin
  class Onboarding < ApplicationRecord
    self.table_name = :onboardings

    has_many :onboarding_steps, dependent: :destroy

    validates_presence_of :title, :description

    def task_info
      begin
        sub_steps = onboarding_steps.map(&:step_completion).map{ |step| JSON.parse step }
        all_steps = sub_steps.reduce({}, :merge)
        [all_steps.length, all_steps.count {|a| a[1]["completion"]}]
      rescue
        return [0,0]
      end
    end

    def completed?
      total_steps, steps_completed = self.task_info
      begin
        (steps_completed.to_f/total_steps.to_f)*100 == 100
      rescue
        false
      end
    end
  end
end
