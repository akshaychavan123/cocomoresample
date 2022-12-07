module BxBlockNotificationSettings
  class SubgroupsController < ApplicationController
    before_action :load_group, only: %i[create update]
    before_action :load_subgroup, only: %i[show update destroy]
    before_action :is_guest, only: %i[create show index destroy update]

    def create
      check_state

      subgroup = BxBlockNotificationSettings::NotificationSubgroup.new(
        permitted_params.except(:token)
      )
      save_result = subgroup.save

      if save_result
        render json: NotificationSubgroupsSerializer.new(subgroup).serializable_hash,
               status: :ok
      else
        render json: ErrorSerializer.new(subgroup).serializable_hash,
               status: :unprocessable_entity
      end
    end

    def show
      return if @subgroup.nil?

      render json: NotificationSubgroupsSerializer.new(@subgroup).serializable_hash,
             status: :ok
    end

    def index
      serializer = NotificationSubgroupsSerializer.new(NotificationSubgroup.all)

      render json: serializer, status: :ok
    end

    def destroy
      return if @subgroup.nil?

      if @subgroup.destroy
        render json: { success: true}, status: :ok
      else
        render json: ErrorSerializer.new(@subgroup).serializable_hash,
               status: :unprocessable_entity
      end
    end

    def update
      return if @subgroup.nil?

      check_state

      update_result = @subgroup.update(permitted_params.except(:token))

      if update_result
        render json: NotificationSubgroupsSerializer.new(@subgroup).serializable_hash,
               status: :ok
      else
        render json: ErrorSerializer.new(@subgroup).serializable_hash,
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
      params.permit(:token, :subgroup_type, :subgroup_name, :state,
                    :notification_group_id)
    end

    def load_group
      @group = NotificationGroup.find_by(id: params[:notification_group_id])

      if @group.nil?
        render json: {
          message: "Group with id #{params[:notification_group_id]} doesn't exists"
        }, status: :not_found
      end
    end

    def load_subgroup
      @subgroup = NotificationSubgroup.find_by(id: params[:id])

      if @subgroup.nil?
        render json: {
          message: "Subgroup with id #{params[:id]} doesn't exists"
        }, status: :not_found
      end
    end

    def check_state
      states = BxBlockNotificationSettings::NotificationSubgroup::STATES

      subgroup_state = states[permitted_params[:state].to_sym]

      raise 'Wrong state value' unless subgroup_state.present?

      if @group.inactive? && subgroup_state == states[:active]
        raise "Subgroup state can't be active due to parent inactive"
      end
    end
  end
end

