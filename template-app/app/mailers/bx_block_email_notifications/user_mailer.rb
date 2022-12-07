module BxBlockEmailNotifications
  class UserMailer < BuilderBase::ApplicationMailer
    include Devise::Mailers::Helpers

    default from: 'admin@store.builder.ai'
    layout 'mailer'

    def welcome_email(user)
      @user = user
      @default_email_setting = BxBlockSettings::DefaultEmailSetting&.first
      @content = BxBlockSettings::EmailSetting.where(event_name: "welcome email").first&.content
      mail(to: @user.email.downcase, subject: "Welcome to #{@default_email_setting&.brand_name}")
    end

    def new_account_otp_verification(email_otp)
      @email_otp = email_otp
      @content = BxBlockSettings::EmailSetting.where(event_name: "new account otp verification").first&.content
      mail(to: @email_otp.email.downcase, subject: 'New Account OTP - Verification')
    end

    def password_changed(email_otp)
      @user = AccountBlock::EmailAccount.find_by(email: email_otp.email, activated: true)
      @email_otp = email_otp
      @content = BxBlockSettings::EmailSetting.where(event_name: "password changed").first&.content
      mail(to: @email_otp.email.downcase, subject: 'OTP for Password Change.')
    end

    def forgot_password_otp_verification(user, email_otp)
      @user = user
      @email_otp = email_otp
      @content = BxBlockSettings::EmailSetting.where(event_name: "forgot password otp verification").first&.content
      mail(to: @user.email.downcase, subject: 'Forgot Password OTP - Verification')
    end
  end
end
