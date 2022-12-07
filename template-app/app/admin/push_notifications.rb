module PushNotifications
  class Load
    @@loaded_from_gem = false
    def self.is_loaded_from_gem
      @@loaded_from_gem
    end

    def self.loaded
    end

    # Check if this file is loaded from gem directory or not
    # The gem directory looks like
    # /template-app/.gems/gems/studio_store_ecommerce_[block_name]-0.0.[version]/app/admin/[admin_template].rb
    # if it has block's name in it then it's a gem
    @@loaded_from_gem = Load.method('loaded').source_location.first.include?('studio_store_ecommerce_')
  end

end

unless PushNotifications::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockNotification::PushNotification, as: "Push Notification" do

    menu false
    permit_params :title, :message

    index do
      selectable_column
      id_column
      column :title
      column :message
      actions defaults: false do |pn|
        link_to 'Send Notification', send_notification_admin_push_notification_path(pn), class: 'view_link member_link'
      end
      actions
    end

    show do
      attributes_table do
        row :id
        row :title
        row :message
      end
    end

    form do |f|
      f.inputs do
        f.input :title
        f.input :message
      end
      f.actions
    end

    member_action :send_notification do
      resource.update(updated_at: Time.now)
      BxBlockNotification::PushNotificationJob.perform_later(resource)
      redirect_back fallback_location: { action: 'index' }
    end
  end
end
