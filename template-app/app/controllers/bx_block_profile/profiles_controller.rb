require 'active_storage'

module BxBlockProfile
  class ProfilesController < ApplicationController
    before_action :is_guest, only: [:show, :update]

    def show
      serializer = AccountBlock::AccountSerializer.new(current_user)
      serialized = serializer.serializable_hash

      render :json => serialized
    end

    def update
      return render json: {message: "Phone number has already been taken."}, status: :unprocessable_entity if is_unique_number(params[:data][:full_phone_number])
      profile_user = current_user
      if profile_user.update(update_profile_params)
        if params[:data][:image].present?
          image_data = split_base64(params[:data][:image])
          blob = ActiveStorage::Blob.create_after_upload!(
            io: StringIO.new((Base64.decode64(params[:data][:image].split(",")[1]))),
            filename: "profile_pic.#{image_data[:extension]}",
            )
          profile_user.image.attach(blob)
        end
        if params[:data][:remove_profile].present? && params[:data][:remove_profile].to_s == "true"
          profile_user.image.purge if profile_user.image.attached?
        end
        render json: AccountBlock::AccountSerializer.new(profile_user, meta: {
          message: 'Your profile has been updated successfully !'
        }).serializable_hash, status: :ok
      else
        render :json => {:errors => [{:profile => profile_user.errors.full_messages}]},
               :status => status
      end
    end

    def split_base64(uri_str)
      if uri_str.match(%r{^data:(.*?);(.*?),(.*)$})
        uri = Hash.new
        uri[:type] = $1 # "image/gif"
        uri[:encoder] = $2 # "base64"
        uri[:data] = $3 # data string
        uri[:extension] = $1.split('/')[1] # "gif"
        return uri
      else
        return nil
      end
    end

    private

    def is_unique_number(phone_number)
      return false if phone_number.blank?
      return AccountBlock::Account.where(full_phone_number: phone_number).where.not(id: current_user.id).present?
    end

    def is_guest
      if @current_user.guest?
        return render json: {message: "Please login or signup to access services"}, status: :unprocessable_entity
      end
    end


    # def current_user
    #   @account = AccountBlock::Account.find(@token&.id)
    # end

    def update_profile_params
      params.require(:data).permit \
        :full_name,
        :email,
        :is_notification_enabled,
        :full_phone_number,
        image: :data
    end
  end
end
