module BxBlockSettings
  class DefaultEmailSetting < ApplicationRecord
    self.table_name = :default_email_settings
    has_one_attached :logo
    validates_presence_of :brand_name, :logo, :recipient_email, :contact_us_email_copy_to
    EMAIL_COPY_METHODS = ['','Bcc', 'Cc']
  end
end
