module BxBlockDashboard
  class DashboardController < ApplicationController
    before_action :load_dashboard, only: [:show, :update, :destroy]

    def create
      dashboard = Dashboard.new(dashboard_params)
      save_result = dashboard.save

      if save_result
        render json: DashboardSerializer.new(dashboard).serializable_hash,
               status: :ok
      else
        render json: ErrorSerializer.new(dashboard).serializable_hash,
               status: :unprocessable_entity
      end
    end

    def show
      return if @dashboard.nil?

      render json: DashboardSerializer.new(@dashboard).serializable_hash,
             status: :ok
    end

    def index
      result = if params['from_date'].present? && params['to_date'].present?
                 zone = Time.zone.name
                 from_date = ActiveSupport::TimeZone[zone].parse(params[:from_date])
                 to_date = ActiveSupport::TimeZone[zone].parse(params[:to_date])

                 Dashboard.where(created_at: from_date..to_date)
               else
                 Dashboard.all
               end
      render json: DashboardSerializer.new(result).serializable_hash,
             status: :ok
    end

    def destroy
      return if @dashboard.nil?

      if @dashboard.destroy
        render json: { success: true }, status: :ok
      else
        render json: ErrorSerializer.new(@dashboard).serializable_hash,
               status: :unprocessable_entity
      end
    end

    def update
      return if @dashboard.nil?

      update_result = @dashboard.update(dashboard_params)

      if update_result
        render json: DashboardSerializer.new(@dashboard).serializable_hash,
               status: :ok
      else
        render json: ErrorSerializer.new(@dashboard).serializable_hash,
               status: :unprocessable_entity
      end
    end

    private

    def load_dashboard
      @dashboard = Dashboard.find_by(id: params[:id])

      if @dashboard.nil?
        render json: {
            message: "Dashboard with id #{params[:id]} doesn't exists"
        }, status: :not_found
      end
    end

    def dashboard_params
      params.permit(:title, :value)
    end
  end
end

