module BxBlockNotificationSettings
  class NotificationSettingsController < ApplicationController
    include NotificationSettingsStates

    before_action :load_setting, only: %i[show update destroy]
    before_action :is_guest, only: %i[create show index destroy update]

    def create
      setting = NotificationSetting.new(permitted_params.except(:token))
      save_result = setting.save

      if save_result
        render json: NotificationSettingsSerializer.new(setting).serializable_hash,
               status: :ok
      else
        render json: ErrorSerializer.new(setting).serializable_hash,
               status: :unprocessable_entity
      end
    end

    def show
      return if @setting.nil?

      render json: NotificationSettingsSerializer.new(@setting).serializable_hash,
             status: :ok
    end

    def index
      settings = NotificationSetting.all
      serializer = NotificationSettingsSerializer.new(settings)

      render json: serializer, status: :ok
    end

    def destroy
      return if @setting.nil?

      if @setting.destroy
        render json: { success: true}, status: :ok
      else
        render json: ErrorSerializer.new(@setting).serializable_hash,
               status: :unprocessable_entity
      end
    end

    def update
      return if @setting.nil?

      update_result = @setting.update(permitted_params.except(:token))

      if update_result
        update_children

        render json: NotificationSettingsSerializer.new(@setting).serializable_hash,
               status: :ok
      else
        render json: ErrorSerializer.new(@setting).serializable_hash,
               status: :unprocessable_entity
      end
    end

    private

    def is_guest
      if @current_user.guest?
        return render json: {message: "Please login or signup to access services"}, status: :unprocessable_entity
      end
    end

    def permitted_params
      params.permit(:token, :title, :description, :state)
    end

    def load_setting
      @setting = NotificationSetting.find_by(id: params[:id])

      if @setting.nil?
        render json: {
          message: "Notification setting with id #{params[:id]} doesn't exists"
        }, status: :not_found
      end
    end

    def update_children
      if inactive_state?(permitted_params[:state])
        @setting.notification_groups.map(&:set_inactive)
      end
    end
  end
end

