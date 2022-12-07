module AppSubmissionRequirements
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

unless AppSubmissionRequirements::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockApiConfiguration::AppSubmissionRequirement, as: 'App Submission Requirement' do
    menu false

    actions :all, except: [:new, :destroy] if  BxBlockApiConfiguration::AppSubmissionRequirement.count > 0

    permit_params :website, :email, :phone, :first_name, :last_name, :address, :city, :state, :postal_code, :country_name, :privacy_policy_url, :support_url, :marketing_url, :terms_and_conditions_url, :app_icon, :common_feature_banner, :app_name, :short_description, :description, :target_audience_and_content, :is_paid, :default_price, :distributed_countries, :auto_price_conversion, :android_wear, :google_play_for_education, :content_guidlines, :us_export_laws, :copyright, :paid, :default_price, :auto_price_conversion, :android_wear, :google_play_for_education, :us_export_laws, :target_audience_and_content, :tags, app_categories_attributes: [:id, :_destroy, :app_name, :product_title, :app_category, :review_username, :review_password, :review_notes, :app_type, :app_icon, :phone, :distributed_country_name, :feature_graphic, :keywords => [], attachments_attributes: [
          :id,
          :image,
          :position,
          :is_default,
          :_destroy
        ] ]

    action_item :download do
      link_to 'download JSON', download_json_response_admin_app_submission_requirements_path(format: :json)
    end unless config.action_items.map(&:name).include?(:download)

    action_item :save_request do
      link_to 'Save Request', save_request_admin_app_submission_requirements_path
    end unless config.action_items.map(&:name).include?(:save_request)

    collection_action :download_json_response, method: :get do
      app_store_requirement = BxBlockApiConfiguration::AppSubmissionRequirement.last
      data = app_store_requirement.get_json_response
      respond_to do |format|
        format.json { send_data data.to_json( include: { categories: { include: { my_cases: { include: [{ questions: { include: :answers } }, :keys ] } } } } ), type: :json, disposition: "attachment; filename=store_requirement.json"}
      end
    end

    collection_action :save_request, method: :get do
      app_store_requirement = BxBlockApiConfiguration::AppSubmissionRequirement.last
      brand_setting = BxBlockStoreProfile::BrandSetting.last
      orders = BxBlockOrderManagement::Order.where(placed_at: (Date.today.at_beginning_of_month..Date.tomorrow))

      url = URI("https://cmt.builder.ai/api/v1/projects/set_configuration")
      Rails.logger.error "<<<<<<<<<<<<<,https://cmt.builder.ai/api/v1/projects/set_configuration>>>>>>>>>"
      http = Net::HTTP.new(url.host, url.port);
      http.use_ssl = true
      request = Net::HTTP::Put.new(url)
      request["token"] = "b39c1b1858c8ee41b1b4c64453597b6a"

      form_data = [['app_config_file_url', app_store_requirement.json_file_service_url],['mobile_branding_file_url', brand_setting.mobile_json_file_service_url || ''],['web_branding_file_url', brand_setting.web_json_file_service_url || ''],['project_id', ENV["HOST_URL"].split("-")[1]],['order_details', {message: "",orders: BxBlockOrderManagement::OrderDetailSerializer.new(orders).serializable_hash, orders_count: orders.count, status: :ok}.to_json]]

      request.set_form form_data, 'multipart/form-data'
      response = http.request(request)

      if response.code == "200"
        flash[:notice] = "Successfully saved data to server"
      else
        flash[:error] = "Something went wrong"
      end
      redirect_to admin_app_submission_requirements_path
    end

    before_save do |requirement|
      requirement.tags = params[:app_submission_requirement][:tags].split(/[\s,]+/) unless params[:app_submission_requirement].nil? or params[:app_submission_requirement][:tags].nil?
    end

    index do
      id_column
      column :app_name
      column :website
      column :email
      column :phone
      column :first_name
      column :last_name
      actions
    end

    form do |f|
      render partial: "admin/email_settings/description.html.erb",locals: { title: 'Set up your business - Submit to app stores', subtitle: "Here's where you add the info needed to submit your app to Apple’s App Store and Google's Play Store." }
      f.inputs do
        f.input :app_name, :input_html => { :class => 'autogrow', :rows => 1, :cols => 20, :maxlength => 30  }
        f.input :short_description, as: :text, :input_html => { :class => 'autogrow', :rows => 5, :cols => 20, :maxlength => 80  }
        f.input :description, as: :text, :input_html => { :class => 'autogrow', :rows => 5, :cols => 20, :maxlength => 4000  }
        f.input :app_icon, :as => :file, :hint => f.object.app_icon.present? ? image_tag(url_for(f.object.app_icon)) : content_tag(:span, "(512px*512px) OR (1024px*1024px) resolution will be good")
        f.input :common_feature_banner, :as => :file, :hint => f.object.common_feature_banner.present? ? image_tag(url_for(f.object.common_feature_banner)) : content_tag(:span, "1024px*500px resolution will be good")
        f.input :tags #, as: :input, multiple: true, collection: BxBlockCatalogue::Tag.all.pluck(:name)

        f.inputs "Contact Details" do
          f.input :website
          f.input :email
          f.input :phone
          f.input :first_name
          f.input :last_name
          f.input :address
          f.input :city
          f.input :state
          f.input :postal_code
          f.input :country_name
        end
        f.inputs "Page Url's" do
          f.input :privacy_policy_url
          f.input :support_url
          f.input :marketing_url
          f.input :terms_and_conditions_url
        end
        f.input :target_audience_and_content, as: :select, collection: BxBlockApiConfiguration::AppSubmissionRequirement::TARGET_AUDIENCE, include_blank: true, allow_blank: false, :prompt => "Select Type"
        f.inputs "Pricing And Distribution" do
          f.input :is_paid
          f.input :default_price
          f.input :distributed_countries
          f.input :auto_price_conversion
          f.input :android_wear
          #f.input :content_guidlines, label: "Content guidelines"
          f.input :google_play_for_education
          f.input :us_export_laws, label: "US export laws"
          f.input :copyright
        end
        f.has_many :app_categories, :multipart => true, allow_destroy: true, heading: 'App Category', new_record: 'Add App Type', class: "" do |ac|
          ac.input :app_type, as: :select, collection: BxBlockApiConfiguration::AppCategory::APP_TYPE, include_blank: true, allow_blank: false, :prompt => "Select Type"
          ac.input :feature_graphic, :as => :file, :hint => ac.object.feature_graphic.present? ? image_tag(url_for(ac.object.feature_graphic)) : content_tag(:span, "120x120 resolution will be good")
          ac.input :product_title
          ac.input :app_category
          ac.input :review_username
          ac.input :review_password
          ac.input :review_notes
          ac.has_many :attachments, as: :attachable, heading: 'Screen Shots',allow_destroy: true, new_record: 'Add Screenshot' do |i|
            i.input :image, as: :file, hint: i.object.image.present? ? image_tag(i.object.image, :size => "260x180") : content_tag(:span, ''), input_html: { class: 'image' }
          end
        end
      end

      f.actions
    end
  end
end
