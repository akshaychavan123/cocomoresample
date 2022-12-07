module AdminProfiles
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

unless AdminProfiles::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockRoleAndPermission::AdminProfile, as: "Profile" do
    config.clear_action_items!

    actions :all, except: [:destroy]

    menu priority: 2, :label=> "<i class='fa fa-edit gray-icon'></i> Edit Profile".html_safe, url: proc {edit_admin_profile_path(current_admin_user.admin_profile)}

    permit_params :name, :phone, :password, :email, :password_confirmation

    form do |f|
      f.inputs 'Edit Profile' do
        if f.object&.admin_user&.super_admin?
          f.input :email, as: 'email'
        else
          f.input :email, as: 'email', input_html: { disabled: true, value: f.object&.admin_user&.email }
        end
        f.input :name
        f.input :phone
        f.input :password, hint: 'must contain 8 char, 1 uppercase, 1 digit, 1 symbol', input_html: {value: f.object.password }
        f.input :password_confirmation, input_html: {value: f.object.password }
      end
      f.actions do
        f.action :submit, label: 'Update'
      end
    end

    controller do
      def update
        super do |_format|
          if resource.valid?
            flash[:notice] = 'Update Successfully.'
            redirect_to edit_admin_profile_path(resource) and return
          else
            flash.now[:error] = resource.errors.full_messages.to_sentence
            render action: 'edit' and return
          end
        end
      end
    end
  end
end
