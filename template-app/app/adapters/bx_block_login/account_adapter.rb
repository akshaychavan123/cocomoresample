module BxBlockLogin
  class AccountAdapter
    include Wisper::Publisher

    def login_account(account_params)
      case account_params.type
      when 'sms_account'
        phone = Phonelib.parse(account_params.full_phone_number).sanitized
        account = AccountBlock::Account.find_by(
          full_phone_number: phone,
          activated: true)
      when 'email_account'
        email = account_params.email&.downcase

        account = AccountBlock::EmailAccount.where('LOWER(email) = ?', email)
        .where(:activated => true).first
      when 'social_account'
        account = AccountBlock::SocialAccount.find_by(
          email: account_params.email.downcase,
          unique_auth_id: account_params.unique_auth_id,
          activated: true)
      end

      unless account.present?
        broadcast(:account_not_found)
        return
      end

      if account.authenticate(account_params.password)
        token = BuilderJsonWebToken.encode(account.id)
        broadcast(:successful_login, account, token)
      else
        broadcast(:failed_login)
      end
    end
  end
end
