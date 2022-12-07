module BxBlockOrderManagement
  class AddAddressToOrder

    attr_accessor :params, :user, :order, :delivery_address, :billing_address

    def initialize(params, user)
      @params = Rails.env.test? ? params['params'] : params
      @user = user
      @order = user.orders.find_by(id: params[:order_id])
    end

    def call
      if params.present?
        set_delivery_address
        if is_address_correct? && delivery_address.save
          user.delivery_addresses.rest_addresses(delivery_address.id).update_all(is_default: false) if delivery_address.is_default

          delivery_address_ids =  order.delivery_addresses.where(address_for: delivery_address.address_for).pluck(:id) if order&.delivery_addresses.present?

          order.delivery_address_orders.address_ids(delivery_address_ids).destroy_all  if delivery_address_ids.present?

          order.delivery_addresses << delivery_address if order.delivery_addresses.where(id: delivery_address.id).blank?

          if delivery_address.address_for == "billing_and_shipping"
            order.delivery_address_orders.find_by(delivery_address_id: delivery_address.id).update(address_for: "billing_and_shipping")
          else
            order.delivery_address_orders.find_by(delivery_address_id: delivery_address.id).update(address_for: "shipping")
          end

          unless params[:billing_same_as_shipping]
            if billing_address.present? && billing_address.save

              user.delivery_addresses.rest_addresses(billing_address.id).update_all(is_default: false) if billing_address.is_default

              billing_address_ids =  order.delivery_addresses.where(address_for: billing_address.address_for).pluck(:id)

              order.delivery_address_orders.address_ids(billing_address_ids).destroy_all  if delivery_address_ids.present?

              order.delivery_addresses << billing_address

              order.delivery_address_orders.find_by(delivery_address_id: billing_address.id).update(address_for: "billing")
            end
          end
          return OpenStruct.new(success?: true, data: {}, msg: 'Address added successfully', code: 200)
        else
          return OpenStruct.new(success?: false, data: nil, msg: "Ooops, Sorry it seems like your address doesn't cover store's delivery area. Try again with valid address", code: 404)
        end
      else
        return OpenStruct.new(success?: false, data: nil, msg: "Ooops, Sorry it seems like you didn't provide the delivery address.", code: 404)
      end
    end

    private

    def is_address_correct?
      delivery_address.present? ? true : false
    end

    def address_params
      params[:address][:country] = params[:address][:country].downcase
      params[:address][:billing_address][:country] = params[:address][:billing_address][:country].downcase
      params[:address][:billing_address][:address_state_id] = params[:address][:billing_address][:address_state_id]

      params.require(:address).permit(:name, :flat_no, :address, :address_line_2, :zip_code, :phone_number, :is_default, :state, :country, :city, :landmark, :address_state_id)
    end

    def billing_params
      params.require(:address).require(:billing_address).permit(:name, :flat_no, :address, :address_line_2, :zip_code, :phone_number, :is_default, :state, :country, :city, :landmark, :address_state_id)
    end

    def set_delivery_address
      address_params[:country] = address_params[:country].downcase

      @delivery_address = params[:delivery_address_id] ? user.delivery_addresses.find(params[:delivery_address_id]) : user.delivery_addresses.new(address_params)
      @delivery_address.is_default = true if user.delivery_addresses.blank?
      @billing_address = params[:billing_address_id] ? user.delivery_addresses.find(params[:billing_address_id]) : user.delivery_addresses.new(billing_params)
      if params[:billing_same_as_shipping]
        order.delivery_address_orders.destroy_all if order&.delivery_address_orders.present?
        @delivery_address.address_for = "billing_and_shipping"
      elsif (params[:address].present? && params[:address][:billing_address].present?) || @billing_address.present?
        shipping_and_billing_ids = order.delivery_addresses.billing_and_shipping.pluck(:id)
        order.delivery_address_orders.address_ids(shipping_and_billing_ids).destroy_all if order&.delivery_address_orders.present?
        @delivery_address.address_for = "shipping"
        # @billing_address = user.delivery_addresses.new(billing_params)
        @billing_address.is_default = true if user.delivery_addresses.blank?
        @billing_address.address_for = "billing"
      end
    end
  end
end
