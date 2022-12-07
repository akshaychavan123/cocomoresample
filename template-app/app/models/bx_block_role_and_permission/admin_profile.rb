module BxBlockRoleAndPermission
  class AdminProfile < BxBlockRoleAndPermission::ApplicationRecord
    self.table_name = :admin_profiles
    belongs_to :admin_user
    before_update :update_admin_user

    PASSWORD_FORMAT = /\A
      (?=.{8,})          # Must contain 8 or more characters
      (?=.*\d)           # Must contain a digit
      (?=.*[A-Z])        # Must contain an upper case character
      (?=.*[[:^alnum:]]) # Must contain a symbol
    /x

    validates :name, :email, :presence => true
    validates :phone, :numericality => true, :length => { :minimum => 10, :maximum => 15 }
    validate :changed_password
    validates :password, allow_nil: true, length: { in: Devise.password_length }, format: { with: PASSWORD_FORMAT }, on: :update

    def changed_password
      unless password == password_confirmation
        self.errors.add(:password, "not matched with confirm password.")
      end
    end

    def update_admin_user
      user = self.admin_user
      user.name = self.name
      user.email = self.email
      user.phone_number = self.phone
      user.password = self.password if self.password.present? && self.password_changed?
      user.save
    end
  end
end

