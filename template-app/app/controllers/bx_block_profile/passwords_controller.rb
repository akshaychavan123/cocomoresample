module BxBlockProfile
  class PasswordsController < ApplicationController
    before_action :is_guest, only: [:update]

    def update
      if current_user.authenticate(params[:data][:current_password])
        if current_user.authenticate(params[:data][:password])
          render :json => {:errors => [message: 'The password is already been used, please try again with another password']},
            :status => :unprocessable_entity
        elsif current_user.update(password: update_params[:password], password_confirmation: update_params[:password_confirmation])
          render json: {message: "Password changed successfully!"}, status: :ok
        else
          render :json => {:errors => [message: "The password you entered did not match. Please try again"]},
          :status => :unprocessable_entity
        end
      else
        render :json => {:errors => [message: "Current password is invalid!"]},
          :status => :unprocessable_entity
      end
    end

    private

    def is_guest
      if current_user.guest?
        return render json: {message: "Please login or signup to access services"}, status: :unprocessable_entity
      end
    end

    def current_user
      @account = AccountBlock::Account.find(@token&.id)
    end

    def update_params
      params.require(:data).permit \
        :current_password,
        :password,
        :password_confirmation
    end
  end
end
