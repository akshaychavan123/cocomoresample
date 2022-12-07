module BxBlockAdmin
  class OnboardingStep < ApplicationRecord
    self.table_name = :onboarding_steps

    default_scope { order(:step) }
    scope :step_number, -> (number) { find_by(step: number) }

    has_one_attached :image
    belongs_to :onboarding

    STEPS = %w[brands email app_banner web_banner taxes shipping third_party_services variants branding categories]

    validates_presence_of :title, :description, :step_completion
    validates :step, presence: true, uniqueness: true, numericality: { only_integer: true, greater_than: 0, less_than: 4 }
    validates :image, content_type: ['image/png', 'image/jpg', 'image/jpeg'], attached: true
    validate :valid_step_completion, :validate_image

    def completed?
      begin
        sub_steps = JSON.parse(step_completion)
        sub_steps.each do |key, value|
          return false unless value["completion"]
        end
        if step == 3
          step_1 = OnboardingStep.step_number(1)
          if step_1.present?
            begin
              data = JSON.parse step_1.step_completion
              return false unless data['branding']['completion']
            rescue
              return false
            end
          end
        end
        return true
      rescue
        return nil
      end
    end

    private

    def valid_step_completion
      begin
        data = JSON.parse(step_completion)

        invalid_steps = []
        data.keys.each do |step|
          invalid_steps << step unless STEPS.include?(step)
        end
        errors.add(:step_completion, "Invalid Steps: '#{invalid_steps.join(', ')}'; Valid Steps: #{STEPS}") if invalid_steps.present?

        if (values = data.values).all? {|v| v.is_a?(Hash) }
          errors.add(:step_completion, "Steps can only contain 'completion' and 'url'") unless values.all? {|v| v.keys.sort == ['completion', 'url']}
          errors.add(:step_completion, "Step completion value can be true or false") unless values.all? {|v| [true, false].include?(v['completion'])}
          errors.add(:step_completion, "Step url is invalid, valid url example: /admin/onboarding_steps/1") unless values.all? {|v| v['url'].match(/^(\/\w+)+$/)}
        else
          errors.add(:step_completion, "Values for steps must be a hash")
        end
      rescue
        errors.add(:step_completion, "must be a hash and steps can be true or false")
      end
    end

    def validate_image
      image_size = FastImage.size(self.attachment_changes['image'].attachable) rescue nil
      return true unless image_size.present?
      if (image_size[0] < 120 || image_size[0] > 800) || (image_size[1] < 120 || image_size[1] > 800)
        errors.add(:image, "The selected file could not be uploaded. The minimum dimensions are 120x120 pixels. The maximum dimensions are 800x800 pixels.")
      end
    end
  end
end
