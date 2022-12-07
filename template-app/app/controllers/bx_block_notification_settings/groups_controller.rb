module BxBlockNotificationSettings
  class GroupsController < ApplicationController
    before_action :load_group, only: %i[show update destroy]
    before_action :load_setting, only: %i[create update]
    before_action :is_guest, only: %i[create show index destroy update]

    def create
      check_state

      group = BxBlockNotificationSettings::NotificationGroup.new(
        permitted_params.except(:token)
      )
      save_result = group.save

      if save_result
        render json: NotificationGroupsSerializer.new(group).serializable_hash,
               status: :ok
      else
        render json: ErrorSerializer.new(group).serializable_hash,
               status: :unprocessable_entity
      end
    end

    def show
      return if @group.nil?

      render json: NotificationGroupsSerializer.new(@group).serializable_hash,
             status: :ok
    end

    def index
      groups = NotificationGroup.all
      serializer = NotificationGroupsSerializer.new(groups)

      render json: serializer, status: :ok
    end

    def destroy
      return if @group.nil?

      if @group.destroy
        render json: { success: true }, status: :ok
      else
        render json: ErrorSerializer.new(@group).serializable_hash,
               status: :unprocessable_entity
      end
    end

    def update
      return if @group.nil?

      check_state

      update_result = @group.update(permitted_params.except(:token))

      if update_result
        render json: NotificationGroupsSerializer.new(@group).serializable_hash,
               status: :ok
      else
        render json: ErrorSerializer.new(@group).serializable_hash,
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
      params.permit(:token, :notification_setting_id, :group_type, :group_name,
                    :state)
    end

    def load_group
      @group = NotificationGroup.find_by(id: params[:id])

      if @group.nil?
        render json: {
          message: "Group with id #{params[:id]} doesn't exists"
        }, status: :not_found
      end
    end

    def load_setting
      setting_id = if params.key?(:notification_setting_id)
                     params[:notification_setting_id]
                   else
                     @group ? @group.notification_setting_id : 0
                   end

      @setting = NotificationSetting.find_by(id: setting_id)

      if @setting.nil?
        render json: {
          message: "Setting with id #{params[:notification_setting_id]} doesn't exists"
        }, status: :not_found
      end
    end

    def check_state
      states = BxBlockNotificationSettings::NotificationGroup::STATES

      group_state = states[permitted_params[:state].to_sym]

      raise 'Wrong state value' unless group_state.present?

      if @setting.inactive? && group_state == states[:active]
        raise "Group state can't be active due to parent inactive"
      end
    end
  end
end
