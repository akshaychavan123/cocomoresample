module BxBlockNotification
  class NotificationsController < ApplicationController
    before_action :fetch_notification, only: [:destroy]
    before_action :load_notifications, only: [:index]

    def index
      render(json: { message: "No notifications found for the user" }, status: 200) && return if @notifications.nil?
      if @notifications
        if @notifications.present? && params[:per_page].present?
          mod = @notifications.count % params[:per_page].to_i
          pages = @notifications.count / params[:per_page].to_i
          pages += 1 if mod > 0
        else
          pages = 0
        end
        count = @notifications.length
        page_no = params[:page].to_i == 0 ? 1 : params[:page].to_i
        per_page = params[:per_page].to_i == 0 ? 10 : params[:per_page].to_i
        @notifications = @notifications.page(page_no).per(per_page)
        render json: {
          success: true,
          data:
          {
            notifications: NotificationSerializer.new(@notifications)
          },
          meta: {
                  pagination: {
                    current_page: @notifications.current_page,
                    next_page: @notifications.next_page,
                    prev_page: @notifications.prev_page,
                    total_pages: pages.present? ? pages : '',
                    total_count: count
                  }
                },
        }, status: 200
      end
    end

    def destroy
      if @notification.present?
        @notification.destroy!
        render json: {
          success: true,
          message: "Notification has been deleted successfuly",
          data: {
            message: "Notification has been deleted successfuly"
          }
        }, status: :ok
      else
        render(json: { message: "Notification not found" }, status: 400)
      end
    end

    def destroy_all
      if @current_user.notifications
        @current_user.notifications.destroy_all
        render(json: { message: "All the notifications are deleted" }, status: 200)
      else
        render(json: { message: "Couldn't delete, something went wrong" }, status: 200)
      end
    end

    def read_notification
      notification = Notification.find_by(id: params[:notification_id])
      if notification.present?
        notification.update(is_read: true)
        render json: {
          success: true,
          data:
          {
            notifications: NotificationSerializer.new(notification)
          }
        }, status: 200
      elsif params[:read_all]
        @current_user.notifications.update_all(is_read: true)
        render json: {
          success: true,
          data:
          {
            notifications: NotificationSerializer.new(@current_user.notifications.order(created_at: :desc))
          }
        }, status: 200
      else
        render(json: { message: "No notification found" }, status: 400)
      end
    end

    private

    def fetch_notification
      @notification = Notification.find_by(id: params[:id])
    end

    def load_notifications
      @notifications = @current_user.notifications.order(created_at: :desc)
    end
  end
end
