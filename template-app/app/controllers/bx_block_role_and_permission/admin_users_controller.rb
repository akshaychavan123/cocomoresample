module BxBlockRoleAndPermission
  class AdminUsersController < BxBlockRoleAndPermission::ApplicationController
    MONTHLY_ORDERS_TOKEN = "bTEQzks87PCxLT4OLf1iAg"
    def create
      admin_user = AdminUser.find_by(email: params[:admin_user][:email], role: 'super_admin')
      if admin_user.present?
        admin_user.update(login_token: generate_token)
        render json: {
            message: "Login Successfully.",
            adminuser: admin_user
        }, status: :ok
      else
        return render json: {errors: [
            {email: 'Admin user was not found'},
        ]}, status: :unprocessable_entity
      end
    end

    def create_super_admin
      super_admins = AdminUser.where(role: 'super_admin')
      return render json: {errors: [{message: "Invalid Token"},]}, status: :unprocessable_entity unless request.headers[:token].to_s == MONTHLY_ORDERS_TOKEN
      return render json: {errors: [{message: "Already created 3 admin users. Following are the emails #{super_admins.pluck(:email).to_sentence}"},]}, status: :unprocessable_entity if super_admins.count > 2
      admin_user = AdminUser.find_by(email: params[:email])
      if admin_user.present?
        return render json: {errors: [
            {email: 'Email is already exist'},
        ]}, status: :unprocessable_entity
      else
        super_admin = AdminUser.new(create_super_admin_params)
        super_admin.activated = true
        super_admin.role = 'super_admin'
        if super_admin.save
          super_admin.update(login_token: generate_token)
          render json: {
              message: "Super admin created.",
              data: {
                  super_admin: super_admin
              }
          }, status: :ok
        else
          return render json: {errors: [
              {errors: super_admin.errors.full_messages},
          ]}, status: :unprocessable_entity
        end
      end
    end

    def update_super_admin
      admin_user = AdminUser.find_by(id: params[:id])
      if admin_user.present?
        if admin_user.update(update_super_admin_params)
          admin_user.update(login_token: generate_token)
          render json: {
              message: "Super admin updated.",
              data: {
                  super_admin: admin_user
              }
          }, status: :ok
        else
          return render json: {errors: [
              {errors: admin_user.errors.full_messages},
          ]}, status: :unprocessable_entity
        end
      else
        return render json: {errors: [
            {email: 'Super admin is not exist'},
        ]}, status: :unprocessable_entity
      end
    end

    def create_store_admin
      super_admin = AdminUser.find_by(login_token: request.headers[:token])
      if super_admin.present?
        store_admin = AdminUser.new(store_admin_params)
        store_admin.role = 'sub_admin'
        if store_admin.save
          render json: {
              message: "Store admin created.",
              store_admin: {
                id: store_admin.id,
                mail: store_admin.email,
                role: store_admin.role,
                name: store_admin.name,
                phone_number: store_admin.phone_number
              }
          }, status: :ok
        else
          return render json: {errors: [
              {errors: store_admin.errors.full_messages},
          ]}, status: :unprocessable_entity
        end
      else
        return render json: {errors: "You are not authorized."}, status: :unprocessable_entity
      end
    end

    def update_store_admin
      super_admin = AdminUser.find_by(login_token: request.headers[:token])
      if super_admin.present?
        store_admin = AdminUser.find_by(id: params[:id])
        if store_admin.present?
          store_admin.update(activated: params[:activate])
          render json: {
              message: "Store admin activated.",
              store_admin: {
                id: store_admin.id,
                email: store_admin.email,
                role: store_admin.role,
                name: store_admin.name,
                phone_number: store_admin.phone_number,
                activated: store_admin.activated
              }
          }, status: :ok
        else
          return render json: {
            errors: "Store admin not found for this id."
          }, status: :unprocessable_entity
        end
      else
        return render json: {errors: "You are not authorized."}, status: :unprocessable_entity
      end
    end

    def create_super_admin_profile
      admin_user = AdminUser.find_by(role: 'super_admin', email: params[:email])
      if admin_user.present?
        unless admin_user&.admin_profile.present?
          admin_name = admin_user.name.present? ? admin_user.name : 'admin'
          admin_phone = admin_user.phone_number.present? ? admin_user.phone_number : '1234567890'
          BxBlockRoleAndPermission::AdminProfile.create!(name: admin_name, phone: admin_phone, email: admin_user&.email, admin_user_id: admin_user.id)
          render json: {
              message: "Super admin profile  created.",
              data: {
                  super_admin: admin_user
              }
          }, status: :ok
        else
          return render json: {errors: "Your admin profile is already exist."}, status: :unprocessable_entity
        end
      else
        return render json: {errors: "Super admin not found for this email."}, status: :unprocessable_entity
      end
    end

    private

    def generate_token
      SecureRandom.hex(50)
    end

    def store_admin_params
      params.permit(:name, :phone_number, :email, :password, permissions: [])
    end

    def create_super_admin_params
      params.permit(:name, :phone_number, :email, :password, :role, :activated)
    end

    def update_super_admin_params
      params.permit(:name, :phone_number, :password, :role, :activated)
    end
  end
end
