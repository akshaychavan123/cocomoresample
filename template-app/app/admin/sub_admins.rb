module SubAdmins
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

unless SubAdmins::Load.is_loaded_from_gem
  ActiveAdmin.register AdminUser, as: 'Sub Admins' do
    menu false
    config.sort_order = 'name_asc'
    permit_params :name, :email, :password, :is_admin, :phone_number, :activated, :role, :permissions => []


    batch_action :destroy, confirm: "Are you sure you want to delete these sub admins?" do |ids|
      if AdminUser.where(id:ids).destroy_all
        flash[:notice]= "Successfully deleted #{ids.count} sub admins"
      else
        flash[:alert]= "Unable to delete sub admins"
      end
      redirect_to collection_path
    end



    form do |f|
      render partial: "admin/email_settings/description.html.erb",locals: { title: 'Create your store - Admins', subtitle: 'Add any other users who need to access this admin panel.' }
      f.inputs 'Sub Admin Details' do
        f.input :name
        f.input :phone_number
        f.input :permissions, as: :select, multiple: true, collection: AdminUser::PERMISSION_KEYWORDS ,input_html: { value: ["Mild"] }
        if object.new_record?
          f.input :email
        else
          f.input :email, input_html: {readonly: true}
        end
        f.input :password if f.object.new_record?


      end
      f.actions do
        f.action :submit, label: f.object.new_record? ? 'Create' : 'Update'
        f.cancel_link(action: 'index')
      end
    end

    # Filterable attributes on the index screen
    filter :name
    filter :email
    filter :created_at

    index :download_links => false do
      selectable_column
      column :name, class: "user"
      column :phone_number, class: "user"
      column "Email", sortable: :email do |user|
        link_to user.email, admin_sub_admin_path(user)
      end
      column :created_at, class: "user"
      actions
    end

    show do
      attributes_table do
        row :name
        row :email
        row :phone_number
        row :permissions
        row :created_at
      end
    end

    controller do

      def create
        params[:admin_user][:permissions] = params[:admin_user][:permissions].reject { |p| p.empty? }
        params[:admin_user][:role] = 'sub_admin'
        params[:admin_user][:activated] = true
        super do |_format|
          if resource.valid?
            flash[:notice] = t('messages.success.created', resource: 'Customer')
            redirect_to(admin_sub_admins_url) and return
          else
            render action: 'new' and return
          end
        end
      end

      def update
        super do |_format|
          if resource.valid?
            flash[:notice] = t('messages.success.updated', resource: 'Customer')
            redirect_to(admin_sub_admins_url) and return
          else
            render action: 'edit' and return
          end
        end
      end

      def destroy
        super do
          flash[:notice] = t('messages.success.deleted', resource: 'Customer')
          redirect_to(admin_sub_admins_url) and return
        end
      end

      def scoped_collection
        super.where(role: 'sub_admin').or(AdminUser.where(email: ENV['EMAIL'] || 'admin2@example.com'))
      end
    end

  end
end
