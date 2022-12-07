module BxBlockContactUs
  class ContactsController < ApplicationController
    include BuilderJsonWebToken::JsonWebTokenValidation
    before_action :validate_json_web_token, only: %i[show, update, destroy, create]
    before_action :find_contact, only: [:show, :update, :destroy]

    def index
      @contacts = Contact.filter(params[:q]).order(:name)

      render json: ContactSerializer
            .new(@contacts)
            .serializable_hash
    end

    def show
      render json: ContactSerializer
            .new(@contact)
            .serializable_hash, status: :ok
    end

    def create
      contact_params = jsonapi_deserialize(params)

      @contact = Contact.new(contact_params)
      @current_user = AccountBlock::Account.find(@token.id) if @token.present?
      if @current_user.present?
        @contact.account_id = @current_user.id
      end
      if @contact.save
        # contact_us_created
        BxBlockEmailNotifications::ContactMailer.with(host: $hostname).contact_us_created(@contact, @current_user).deliver
        render json: {
              success: true,
              message: ' ',
              data: {contact_us: @contact},
              meta: [],
              errors: []
            }
      else
        render json: {errors: [
          {contact: @contact.errors.full_messages},
        ]}, status: :unprocessable_entity
      end
    end

    def update
      contact_params = jsonapi_deserialize(params)

      if @contact.update(contact_params)
        render json: ContactSerializer
              .new(@contact)
              .serializable_hash, status: 200
      else
        render json: {errors: [
          {contact: @contact.errors.full_messages},
        ]}, status: :unprocessable_entity
      end
    end

    def destroy
      @contact.destroy

      render json: {
        message: "Contact destroyed successfully"
      }, status: 200
    end

    private

    def find_contact
      begin
        @contact = Contact.find(params[:id])
      rescue ActiveRecord::RecordNotFound => e
        return render json: {errors: [
          {contact: 'Contact Not Found'},
        ]}, status: 404
      end
    end
  end
end
