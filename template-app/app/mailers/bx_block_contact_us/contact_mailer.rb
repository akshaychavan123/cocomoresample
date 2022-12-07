module BxBlockContactUs
  class ContactMailer < ApplicationMailer
    def contact_us_created(contact)
      # @contact = contact
      # @user = user
      # @admin_user = AdminUser.first
      # @content = BxBlockSettings::EmailSetting.where(event_name: "contact us").first&.content
      # @default_email_setting = BxBlockSettings::DefaultEmailSetting.first
      # mail(to: @default_email_setting.contact_us_email_copy_to, subject: 'new user wants to contact.')
    end
  end
end
