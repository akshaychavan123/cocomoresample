module EmailSettings
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

unless EmailSettings::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockSettings::EmailSetting, as: "EmailSetting" do
    menu false
    permit_params :title, :event_name, :content

    action_item :email_setting, if: proc { action_name == 'index' } do
      path = BxBlockSettings::DefaultEmailSetting.last.present? ? edit_admin_default_email_setting_path(BxBlockSettings::DefaultEmailSetting.last) : new_admin_default_email_setting_path
      link_to 'Default Email Setting', path
    end

    action_item :generate_email_templates do
      link_to 'Generate Templates', generate_email_templates_admin_email_settings_path, method: :post
    end

    collection_action :generate_email_templates, method: :post do
      email_template = BxBlockSettings::EmailSetting.generate_email_template
      redirect_to request.referer, notice: 'Email templates generated successfully.'
    end


    form do |f|
      render partial: 'admin/email_settings/description.html.erb',locals: { title: 'Create your store - Email',
                                                                            subtitle: 'Create templates for your customer emails (eg Welcome email, New order email).' }
      f.inputs 'Email Setting Details'  do
        f.input :title
        f.input :event_name, as: :select, collection: BxBlockSettings::EmailSetting.event_names.keys.to_a, include_blank: true, allow_blank: false, :prompt => "Select Event",input_html: { class: 'select2' }
        f.input :content, as: :ckeditor, input_html: { class: 'email_settings_cont'}
        panel 'Available Keywords' do
          keywords = (BxBlockSettings::EmailSetting::ORDER_EMAIL_KEYWORDS + BxBlockSettings::EmailSetting::CUSTOMER_EMAIL_KEYWORDS + BxBlockSettings::EmailSetting::EMAIL_KEYWORDS).uniq
          keywords.map{|key| "<span class='keyword-span'>%{#{key}}</span>"}.join(' ').to_s.html_safe
        end
      end
      f.actions do
        f.action :submit
        f.cancel_link(action: 'index')
      end
    end


    index :download_links => false do
      selectable_column
      id_column
      column :title
      actions
    end

    controller do
      # def find_resource
      #   #scoped_collection.friendly.find(params[:id])
      # end
    end
  end
end
