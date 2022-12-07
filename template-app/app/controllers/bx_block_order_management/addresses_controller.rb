module BxBlockOrderManagement
  class AddressesController < ApplicationController
    before_action :get_user, only: [:index, :create, :show, :destroy, :update, :get_address_states]
    before_action :check_country, only: [:get_address_states]
    before_action :fetch_address, only: [:show, :destroy, :update]
    before_action :is_guest, only: %i[index, create, show, destroy, update]

    def index
      addresses = @current_user.delivery_addresses
      render json: AddressesSerializer.new(addresses).serializable_hash,
             status: :ok
    end

    def create
      params[:address][:country] = params[:address][:country].downcase
      if params[:address][:country] != "india" and params[:address][:country] != "uk"
        return render json: {
          errors: [{
                     country: 'country is not valid',
                   }],
        }, status:  400
      else
        delivery_address = @current_user.delivery_addresses.new(address_params)
        delivery_address.is_default = true if @current_user.delivery_addresses.blank?
        delivery_address.save!
        @current_user.delivery_addresses.rest_addresses(delivery_address.id).update_all(is_default: false) if delivery_address.is_default
        render json: AddressesSerializer.new(delivery_address, serialize_options).serializable_hash,
               message: 'Address added successfully ', status: :ok
      end
    end

    def show
      render json: AddressesSerializer.new(@delivery_address, serialize_options).serializable_hash,
             status: :ok
    end

    def destroy
      @delivery_address.destroy
      render json: { message: 'Address deleted successfully' }, status: :ok
    end

    def update
      params[:address][:country] = params[:address][:country].to_s.downcase if params[:address].present? && params[:address][:country].present?
      if params[:address].present? && params[:address][:country].present? && params[:address][:country] != "india" and params[:address][:country] != "uk"
        return render json: {
          errors: [{
                     country: 'country is not valid',
                   }],
        }, status:  400
      else
        @delivery_address.update!(address_params)
        @current_user.delivery_addresses.rest_addresses(@delivery_address.id).update_all(is_default: false) if @delivery_address.is_default
        render json: AddressesSerializer.new(@delivery_address, serialize_options).serializable_hash,
               message: 'Address updated successfully ', status: :ok
      end
    end

    def check_zipcode_available
      zipcode = BxBlockZipcode::Zipcode.activated.find_by(code: params[:zipcode])
      if zipcode.present?
        render json: { message: 'Delivery available for this location' }, status: :ok
      else
        render(json: { message: "Sorry, currently delivery is not available for this location." }, status: 400)
      end
    end

    def get_address_states
      address_states = BxBlockOrderManagement::AddressState.all.order('name ASC')
      render json: AddressStatesSerializer.new(address_states).serializable_hash,
             status: :ok
    end

    private

    def is_guest
      if @current_user.guest?
        return render json: {message: "Please login or signup to access services"}, status: :unprocessable_entity
      end
    end

    def address_params
      params[:address][:country] = params[:address][:country].to_s.downcase if params[:address].present? && params[:address][:country].present?
      params.require(:address).permit(:name, :flat_no, :address_type, :address, :address_line_2, :zip_code, :phone_number, :latitude, :longitude, :is_default, :state, :country, :city, :landmark, :address_state_id)
    end

    def fetch_address
      @delivery_address = @current_user.delivery_addresses.find(params[:id])
    end

    def serialize_options
      { params: { user: @current_user } }
    end

    def check_country
      brand_setting = BxBlockStoreProfile::BrandSetting.first
      if brand_setting.present? && !brand_setting.country_india?
        render :json => {'errors' => ['Country not set to India']}
      end
    end

  end
end
