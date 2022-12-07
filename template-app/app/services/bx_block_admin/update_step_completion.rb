module BxBlockAdmin
  class UpdateStepCompletion
    def initialize(sub_step, model_name)
      @sub_step = sub_step
      @model_name = model_name
    end

    def call
      step = BxBlockAdmin::OnboardingStep.select{|step| step.step_completion.include?(@sub_step)}.last
      if step.present?
        begin
          data = JSON.parse step.step_completion
          if data[@sub_step].present?
            if ["app_banner", "web_banner"].include?(@sub_step)
              if @sub_step == "app_banner"
                data[@sub_step]['completion'] = @model_name.constantize.exists?(web_banner: false)
              else
                data[@sub_step]['completion'] = @model_name.constantize.exists?(web_banner: true)
              end
            else
              data[@sub_step]['completion'] = @model_name.constantize.any?
            end
            step.step_completion = data.to_json
            step.save
          end
        rescue
          return
        end
      end
    end
  end
end
