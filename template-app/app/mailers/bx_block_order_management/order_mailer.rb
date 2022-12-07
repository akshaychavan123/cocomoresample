module BxBlockOrderManagement
  class OrderMailer < BxBlockOrderManagement::ApplicationMailer
    include Devise::Mailers::Helpers

    default from: 'admin@store.builder.ai'
    layout 'mailer'

    def contact_us_created(user)
      @user = user
      @admin_user = AdminUser.first
      @content = BxBlockSettings::EmailSetting.where(event_name: "contact us").first&.content
      @default_email_setting = BxBlockSettings::DefaultEmailSetting.first
      mail(to: @default_email_setting.contact_us_email_copy_to, subject: 'new user wants to contact.')
    end


    def order_confirmed(order)
      @order = order
      @user = order.account
      delivery_addresses = order.delivery_addresses
      if delivery_addresses.first&.address_for.to_s.downcase == 'billing_and_shipping'
        @billing_address = delivery_addresses.first
        @shipping_address = delivery_addresses.first
      else
        @billing_address = order.delivery_addresses.where(address_for: 'billing').first
        @shipping_address = order.delivery_addresses.where(address_for: 'shipping').first
      end
      @content = BxBlockSettings::EmailSetting.where(event_name: "order confirmed").first&.content
      mail(to: @user.email.downcase, subject: 'Order confirmed.')
    end

    def order_in_transit(order)
      @order = order
      @user = order.account
      @content = BxBlockSettings::EmailSetting.where(event_name: "order shipped").first&.content
      mail(to: @user.email.downcase, subject: 'Order shipped.')
    end

    def order_cancelled(order)
      @order = order
      @user = order.account
      @content = BxBlockSettings::EmailSetting.where(event_name: "order cancelled").first&.content
      mail(to: @user.email.downcase, subject: 'Order Cancelled.')
    end

    def order_status_notification(order)
      @order = order
      @user = order.account
      @content = BxBlockSettings::EmailSetting.where(event_name: "order status").first&.content
      mail(to: @user.email.downcase, subject: "Order #{@order.status}.")
    end

    def order_placed(order)
      @order = order
      @user = order.account
      delivery_addresses = @order.delivery_addresses
      if delivery_addresses.first&.address_for.to_s.downcase == 'billing_and_shipping'
        @billing_address = delivery_addresses.first
        @shipping_address = delivery_addresses.first
      else
        @billing_address = @order.delivery_addresses.where(address_for: 'billing').first
        @shipping_address = @order.delivery_addresses.where(address_for: 'shipping').first
      end
      @content = BxBlockSettings::EmailSetting.where(event_name: "new order").first&.content
      mail(to: @user.email.downcase, subject: "Order placed")
    end

    def admin_order_placed(order)
      @order = order
      @user = order.account
      delivery_addresses = @order.delivery_addresses
      @to_admin = true
      if delivery_addresses.first&.address_for.to_s.downcase == 'billing_and_shipping'
        @billing_address = delivery_addresses.first
        @shipping_address = delivery_addresses.first
      else
        @billing_address = @order.delivery_addresses.where(address_for: 'billing').first
        @shipping_address = @order.delivery_addresses.where(address_for: 'shipping').first
      end
      @content = BxBlockSettings::EmailSetting.where(event_name: "admin new order").first&.content
      @default_email_setting = BxBlockSettings::DefaultEmailSetting.first
      mail(to: @default_email_setting.recipient_email, subject: "New order received.")
    end
  end
end
