module BxBlockNotificationSettings
  module NotificationSettingsStates
    STATES = {
      active: 1,
      inactive: 0
    }.freeze

    def active_state?(state)
      raise "Wrong state - #{state}" unless STATES.key?(state.to_sym)

      STATES[state.to_sym] == STATES[:active]
    end

    def inactive_state?(state)
      raise "Wrong state - #{state}" unless STATES.key?(state.to_sym)

      STATES[state.to_sym] == STATES[:inactive]
    end
  end
end
