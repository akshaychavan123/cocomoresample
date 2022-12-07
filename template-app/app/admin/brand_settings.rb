module BrandSettings
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

unless BrandSettings::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockStoreProfile::BrandSetting, as: 'Brand Setting' do
    menu false

    permit_params :heading, :country, :sub_heading, :description, :header_color, :common_button_color, :button_hover_color, :logo, :promotion_banner, :description_font_color, :phone_number, :copyright_message, :fb_link, :instagram_link, :twitter_link, :youtube_link, :footer_message, :google_app, :app_store, :app_icon, :login_icon, :bottom_tab_icon, :profile_screen_icon, :cart_and_notification_icon, :currency_type, :brand_text_color, :active_tab_color, :inactive_tab_color, :active_text_color, :inactive_text_color, :button_hover_text_color, :border_color, :sidebar_bg_color, :copyright_message, :wishlist_icon_color, :wishlist_btn_text_color, :order_detail_btn_color, :api_key, :auth_domain, :database_url, :project_id, :storage_bucket, :messaging_sender_id, :app_id, :measurement_id, :is_facebook_login, :is_google_login, :is_apple_login, :primary_color, :address, :gst_number, :cropped_image, :highlight_primary_color, :highlight_secondary_color, :address_state_id,:template_selection, :color_palet, :whatsapp_number,:whatsapp_message, :is_whatsapp

    actions :all, :except =>[:destroy]

    action_item :download do
      link_to 'Web JSON', download_web_response_admin_brand_settings_path(format: :json)
    end

    action_item :single_hash_download do
      link_to 'Mobile JSON', download_mobile_json_admin_brand_settings_path(format: :json)
    end


    collection_action :download_web_response, method: :get do
      brand_setting = BxBlockStoreProfile::BrandSetting.last
      data = brand_setting.nested_response_hash
      respond_to do |format|
        format.json { send_data data.to_json( include: { categories: { include: { my_cases: { include: [{ questions: { include: :answers } }, :keys ] } } } } ), type: :json, disposition: "attachment; filename=web.json"}
      end
    end

    collection_action :download_mobile_json, method: :get do
      brand_setting = BxBlockStoreProfile::BrandSetting.last
      data = brand_setting.simple_response_hash
      respond_to do |format|
        format.json { send_data data.to_json( include: { categories: { include: { my_cases: { include: [{ questions: { include: :answers } }, :keys ] } } } } ), type: :json, disposition: "attachment; filename=mobile.json"}
      end
    end

    collection_action :download, method: :get do
      if params[:play_store] == 'true'
        file_name = Rails.root + "lib/play_store_requirement.doc"
      else
        file_name = Rails.root + "lib/app_store_requirements.docx"
      end
      send_file file_name, type: "application/csv"
    end

    collection_action :upload_file, method: :post do
      flash[:notice] = "File uploaded successfully."
      redirect_to(admin_app_requirement_url) and return
    end

    index :download_links => false do
      selectable_column
      id_column
      column :country
      column :heading
      column :sub_heading
      column :phone_number
      column :copyright_message
      column :fb_link
      column :instagram_link
      column :twitter_link
      column :youtube_link
      column :footer_message
      actions
    end

    form :html => {:multipart => true} do |f|
      render partial: "admin/email_settings/description.html.erb",locals: { title: 'Create your store - Branding', subtitle: 'Add your logo and pick the colours you want for your store.' }
      f.inputs do
        f.input :heading, label: "Store Name <span class='tooltip'><i class='fas fa-info-circle info-icon'><span class='tooltiptext'>What do you want your store to be called?</span></i></span>".html_safe
        f.input :logo, :as => :file, label:"Logo <div class='tooltip'><i class='fas fa-info-circle info-icon'><div class='tooltiptext'>Add a logo for your store</div></i></div>".html_safe, input_html: {id: 'brandSettingLogo', class: 'image cropper', 'cropped-image-temp-store-id': '#croppedImageTempStore'}, :hint => f.object.logo.present? ? image_tag(url_for(f.object.logo), class:"preview") : content_tag(:span, "120x120 resolution will be good")
        f.input :cropped_image, :as => :hidden, input_html: {id: 'croppedImageTempStore'}
        f.input :promotion_banner, label:"Main Banner <span class='tooltip'><i class='fas fa-info-circle info-icon'><span class='tooltiptext'>Upload a banner to appear on the main page of your store</span></i></span>".html_safe, :as => :file, :hint => f.object.promotion_banner.present? ? image_tag(url_for(f.object.promotion_banner)) : content_tag(:span, "for web footer.")

        f.input :country,label: "Country <span class='tooltip'><i class='fas fa-info-circle info-icon'><span class='tooltiptext'>Where is your store based?</span></i></span>".html_safe, input_html: { class: 'brand_setting_country'}
        f.input :address_state_id, as: :select, collection: BxBlockOrderManagement::AddressState.all.order('name ASC').map { |u| [u.name.to_s.titleize, u.id] }, :prompt => "Select State"
        f.input :currency_type,label: "Currency <span class='tooltip'><i class='fas fa-info-circle info-icon'><span class='tooltiptext'>What currency do you want to use for the products in your store?</span></i></span>".html_safe, input_html: { readonly: false }
        f.input :sub_heading, label: 'Tag Line'
        f.input :phone_number, label: "Contact Phone Number <span class='tooltip'><i class='fas fa-info-circle info-icon'><span class='tooltiptext'>The main contact phone number of your store</span></i></span>".html_safe, hint: "<span>For web.</span>".html_safe, :input_html => { :type => 'number', min: 0 }
        f.input :copyright_message, label: "Copyright message <span class='tooltip'><i class='fas fa-info-circle info-icon'><span class='tooltiptext'>This copyright text will appear in the bottom of the page</span></i></span>".html_safe
        f.input :address
        f.input :gst_number
        f.inputs "Template Selection" do
          f.input :template_selection, as: :radio, :label => "Template Selection",:value_as_class => true,:wrapper_html => { :class => "special" },:input_html => { :size => 20, :class => "special-radio-button-image" }, :collection => [ 'Minimal', 'Prime','Bold','Ultra','Essence']
          f.input :color_palet, as: :radio, :label => "Color palette",:value_as_class => true,:wrapper_html => { :class => "special" },:input_html => { :size => 20, :class => "special-radio-color-pallate" }, :collection => [ ['Sky',"{themeName: 'Sky',primaryColor:'#364F6B',secondaryColor:'#3FC1CB'}"], ['Navy',"{themeName: 'Navy',primaryColor:'#011638',secondaryColor:'#FE5F55'}"],['Bonsai',"{themeName: 'Bonsai',primaryColor:'#4A6C6F',secondaryColor:'#7FB069'}"],['Forest',"{themeName: 'Forest',primaryColor:'#0B3C49',secondaryColor:'#BE7C4D'}"],['Wood',"{themeName: 'Wood',primaryColor:'#6F1A07',secondaryColor:'#AF9164'}"],['Wine',"{themeName: 'Wine',primaryColor:'#731963',secondaryColor:'#C6878F'}"],['Glitter',"{themeName: 'Glitter',primaryColor:'#642CA9',secondaryColor:'#FF36AB'}"]]
        end


        f.inputs 'Social Media Pages' do

          f.input :fb_link, label: "Facebook Link <span class='tooltip'><i class='fas fa-info-circle info-icon'><span class='tooltiptext'>Add the link to your store's Facebook page</span></i></span>".html_safe
          f.input :instagram_link, label: "Instagram Link <span class='tooltip'><i class='fas fa-info-circle info-icon'><span class='tooltiptext'>Add the link to your store's Instagram page</span></i></span>".html_safe
          f.input :twitter_link, label: "Twitter Link <span class='tooltip'><i class='fas fa-info-circle info-icon'><span class='tooltiptext'>Add the link to your store's Twitter page</span></i></span>".html_safe
          f.input :youtube_link,label: "Youtube Link <span class='tooltip'><i class='fas fa-info-circle info-icon'><span class='tooltiptext'>Add the link to your store's Youtube page</span></i></span>".html_safe
          f.input :is_facebook_login,label: "Is Facebook Login <span class='tooltip'><i class='fas fa-info-circle info-icon'><span class='tooltiptext'>Do you want to allow users to login with their Facebook account?</span></i></span>".html_safe
          f.input :is_google_login,label: "Is Google Login <span class='tooltip'><i class='fas fa-info-circle info-icon'><span class='tooltiptext'>Do you want to allow users to login with their Google account?</span></i></span>".html_safe
          f.input :is_apple_login, label: "Is Apple Login <span class='tooltip'><i class='fas fa-info-circle info-icon'><span class='tooltiptext'>Do you want to allow users to login with their Apple account?</span></i></span>".html_safe
        end
        f.inputs 'Whatsapp Integration' do
          # f.input :is_whatsapp, label: "Whatsapp Integration ",:input_html => { :class => "tooltiptext" },:as => :radio,
          #  :collection => {"Yes" => true, "No" => false}
          f.input :whatsapp_number,label: "Whatsapp Number <span class='tooltip'><i class='fas fa-info-circle info-icon'><span class='tooltiptext'>Add 10 digit what's app number where you want to receive messages</span></i></span>".html_safe
          f.input :whatsapp_message, label:"Welcome Message <span class='tooltip'><i class='fas fa-info-circle info-icon'><span class='tooltiptext'>Add pre-filled message that will automatically appear in the text field of a chat.
          </span></i></span>".html_safe, :input_html => { :class=> "wa-msg-field", :type => 'number', min: 0 }
        end
        # f.inputs "Button Color" do
        #   f.input :active_text_color, label: 'Regular text color'
        #   f.input :common_button_color, label: 'Button background color',:hint => image_tag("/assets/common-button-color.jpg")
        #   f.input :brand_text_color, label: 'Button text color',:hint => image_tag("/assets/common-button-text-color.jpg")
        #   f.input :button_hover_color, label: 'Button hover color (for web)',:hint => image_tag("/assets/button-hover-color.jpg")
        # end
        f.inputs "Other Colors(App)" do
          f.input :primary_color
          # f.input :highlight_primary_color
          # f.input :highlight_secondary_color
        end
        f.inputs 'Firebase Account' do
          f.input :api_key, label: 'Server key'
          f.input :auth_domain
          f.input :database_url
          f.input :project_id
          f.input :storage_bucket
          f.input :messaging_sender_id
          f.input :app_id
          f.input :measurement_id
        end
      end
      f.actions
      div do
        render partial: 'new'
      end
    end

    controller do
      def action_methods
        if BxBlockStoreProfile::BrandSetting.first.present?
          super - ['new']
        else
          super
        end
      end
    end

  end
end

module BrandSettings
end
