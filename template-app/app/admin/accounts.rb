module Accounts
  class Load
    @@loaded_from_gem = false
    def self.is_loaded_from_gem
      @@loaded_from_gem
    end

    def self.loaded
    end

    # Check if this file is loaded from gem directory or not
    # The gem directory looks like
    # /template-app/.gems/gems/studio_store_ecommerce_[block_name]-0.0.[version]/app/admin/[admin_template].rb
    # if it has block's name in it then it's a gem
    @@loaded_from_gem = Load.method('loaded').source_location.first.include?('studio_store_ecommerce_')
  end

end

unless Accounts::Load.is_loaded_from_gem
  ActiveAdmin.register AccountBlock::Account, as: "Accounts" do
    menu :label=> "<i class='fa fa-user gray-icon'></i> Customers".html_safe, priority: 4
    permit_params :full_name,
    :email,
    :password,
    :activated,
    :full_phone_number,
    :phone_number,
    :image,
    delivery_addresses_attributes: [
      :id,
      :name,
      :flat_no,
      :address,
      :address_line_2,
      :city,
      :state,
      :country,
      :zip_code,
      :phone_number
    ]

    action_item :contact_us, only: :index do
      link_to 'Inbound Queries', admin_contact_us_path, class: 'customer-inbound-queries'
    end

    action_item :reviews, only: :index do
      link_to 'Reviews', admin_reviews_path, class: 'customer-reviews'
    end

    batch_action :destroy, confirm: "Are you sure you want to delete these users?" do |ids|
      ActiveRecord::Base.connection.disable_referential_integrity do
        if AccountBlock::Account.where(id:ids).destroy_all
          flash[:notice]= "Successfully deleted #{ids.count} users"
        else
          flash[:alert]= "Unable to delete users"
        end
      end
      redirect_to collection_path
    end

    action_item :export_all_users_list, if: proc { action_name == 'index' } do
      link_to 'Export All Customers list', { action: 'export_all_users_list' }, class: 'export-customer-list'
    end

    collection_action :export_all_users_list, method: :get do
      users = AccountBlock::Account.order(first_name: :asc)
      temp_csv = CSV.generate(encoding: 'UTF-8') do |csv|
        # add headers
        csv << %w[Name PhoneNumber Email Suspended CreatedAt]
        # add data
        users.each do |user|
          suspended = "No"
          csv << [user&.first_name, user&.phone_number, user&.email, suspended, user&.created_at]
        end
      end
      # send file to user
      send_data temp_csv.encode('UTF-8'), type: 'text/csv; charset=UTF-8; header=present', disposition: "attachment; filename=customers_#{Date.today.strftime('%d_%m_%Y')}.csv"
    end


    form do |f|
      f.semantic_errors
      f.inputs do
        f.input :full_name
        f.input :email
        f.input :password if f.object.new_record?
        f.input :full_phone_number
        f.input :activated, as: :boolean
        f.input :image, :as => :file
        if f.object&.image&.attached? && f.object.id
          if f.object.image.id
            div :class=> "row" do
              div :class=> "col-xs-8" do
                image_tag(f.object.image)
              end
              div :class=> "col-xs-4" do
                link_to "delete",delete_image_admin_account_path(f.object.id, image_id: f.object.image.id),method: :delete,data: { confirm: 'Are you sure?' }
              end
            end
          end
        end
        f.has_many :delivery_addresses, :multipart => true, allow_destroy: true do |address|
          address.input :name
          address.input :flat_no
          address.input :address
          address.input :address_line_2
          address.input :zip_code
          address.input :phone_number
          address.input :city
          address.input :state
          address.input :country
        end
      end
      f.actions
    end

    index do
      selectable_column
      id_column
      column :full_name
      column 'Email' do |account|
        link_to account.email, admin_account_path(account)
      end
      column :full_phone_number
      column :activated
      column :type
      column :provider
      column :created_at
      column :updated_at
      actions
    end

    show do
      attributes_table do
        row :full_name
        row :image do |account|
          div :class => "col-xs-4" do
            image_tag(url_for(account.image)) if account.image.present?
          end
        end
        row :email
        row :full_phone_number
        row :activated
        row :type
        row :provider
        row :created_at
        row :updated_at
      end
    end

    filter :full_name
    filter :email
    filter :full_phone_number
    filter :activated
    filter :provider
    filter :type
    filter :created_at
    filter :updated_at

    controller do
      def scoped_collection
        AccountBlock::Account.where.not(type: 'guest_account')
      end

      def create
        super do |_format|
          if resource.valid?
            flash[:notice] = 'Customer created successfully.'
            resource.update(activated: true, type: "EmailAccount")
            redirect_to(admin_accounts_url) and return
          else
            flash.now[:error] = resource.errors.full_messages.to_sentence
            render :new  and return
          end
        end
      end

      def update
        resource = AccountBlock::Account.find_by(id: permitted_params[:id])
        resource.attributes = permitted_params[:account]
        if resource.save(validate: false)
          flash[:notice] = 'updated successfully.'
          redirect_to(admin_accounts_url) and return
        else
          flash.now[:error] = resource.errors.full_messages.to_sentence
          render :new and return
        end
      end

      def destroy
        ActiveRecord::Base.connection.disable_referential_integrity do
          super do
            flash[:notice] = t('messages.success.deleted', resource: 'Customer')
            redirect_to(admin_accounts_url) and return
          end
        end
      end
    end

    member_action :delete_image, method: :delete do
      @pic = ActiveStorage::Attachment.find(params[:image_id])
      @pic.purge_later
      redirect_back(fallback_location: edit_admin_account_path(params[:id]))
    end
  end
end
