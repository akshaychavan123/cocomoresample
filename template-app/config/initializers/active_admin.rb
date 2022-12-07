ActiveAdmin.setup do |config|
  # == Site Title
  #
  # Set the title that is displayed on the main layout
  # for each of the active admin pages.
  #
  config.site_title = "Studio Store"

  # Set the link url for the title. For example, to take
  # users to your main site. Defaults to no link.
  #
  # config.site_title_link = "/"

  # Set an optional image to be displayed for the header
  # instead of a string (overrides :site_title)
  #
  # Note: Aim for an image that's 21px high so it fits in the header.
  #
  # config.site_title_image = "logo.png"

  # == Default Namespace
  #
  # Set the default namespace each administration resource
  # will be added to.
  #
  # eg:
  #   config.default_namespace = :hello_world
  #
  # This will create resources in the HelloWorld module and
  # will namespace routes to /hello_world/*
  #
  # To set no namespace by default, use:
  #   config.default_namespace = false
  #
  # Default:
  # config.default_namespace = :admin
  #
  # You can customize the settings for each namespace by using
  # a namespace block. For example, to change the site title
  # within a namespace:
  #
  #   config.namespace :admin do |admin|
  #     admin.site_title = "Custom Admin Title"
  #   end
  #
  # This will ONLY change the title for the admin section. Other
  # namespaces will continue to use the main "site_title" configuration.

  # == User Authentication
  #
  # Active Admin will automatically call an authentication
  # method in a before filter of all controller actions to
  # ensure that there is a currently logged in admin user.
  #
  # This setting changes the method which Active Admin calls
  # within the application controller.
  config.authentication_method = :authenticate_admin_user!

  # == User Authorization
  #
  # Active Admin will automatically call an authorization
  # method in a before filter of all controller actions to
  # ensure that there is a user with proper rights. You can use
  # CanCanAdapter or make your own. Please refer to documentation.
  config.authorization_adapter = ActiveAdmin::CanCanAdapter
  config.cancan_ability_class = "BxBlockRoleAndPermission::AdminAbility"

  # In case you prefer Pundit over other solutions you can here pass
  # the name of default policy class. This policy will be used in every
  # case when Pundit is unable to find suitable policy.
  # config.pundit_default_policy = "MyDefaultPunditPolicy"

  # If you wish to maintain a separate set of Pundit policies for admin
  # resources, you may set a namespace here that Pundit will search
  # within when looking for a resource's policy.
  # config.pundit_policy_namespace = :admin

  # You can customize your CanCan Ability class name here.
  # config.cancan_ability_class = "Ability"

  # You can specify a method to be called on unauthorized access.
  # This is necessary in order to prevent a redirect loop which happens
  # because, by default, user gets redirected to Dashboard. If user
  # doesn't have access to Dashboard, he'll end up in a redirect loop.
  # Method provided here should be defined in application_controller.rb.
  # config.on_unauthorized_access = :access_denied

  # == Current User
  #
  # Active Admin will associate actions with the current
  # user performing them.
  #
  # This setting changes the method which Active Admin calls
  # (within the application controller) to return the currently logged in user.
  config.current_user_method = :current_admin_user

  # == Logging Out
  #
  # Active Admin displays a logout link on each screen. These
  # settings configure the location and method used for the link.
  #
  # This setting changes the path where the link points to. If it's
  # a string, the strings is used as the path. If it's a Symbol, we
  # will call the method to return the path.
  #
  # Default:
  config.logout_link_path = :destroy_admin_user_session_path

  # This setting changes the http method used when rendering the
  # link. For example :get, :delete, :put, etc..
  #
  # Default:
  # config.logout_link_method = :get

  # == Root
  #
  # Set the action to call for the root path. You can set different
  # roots for each namespace.
  #
  # Default:
  # config.root_to = 'dashboard#index'

  # == Admin Comments
  #
  # This allows your users to comment on any resource registered with Active Admin.
  #
  # You can completely disable comments:
  config.comments = false
  #
  # You can change the name under which comments are registered:
  # config.comments_registration_name = 'AdminComment'
  #
  # You can change the order for the comments and you can change the column
  # to be used for ordering:
  # config.comments_order = 'created_at ASC'
  #
  # You can disable the menu item for the comments index page:
  # config.comments_menu = false
  #
  # You can customize the comment menu:
  # config.comments_menu = { parent: 'Admin', priority: 1 }

  # == Batch Actions
  #
  # Enable and disable Batch Actions
  #
  config.batch_actions = true

  # == Controller Filters
  #
  # You can add before, after and around filters to all of your
  # Active Admin resources and pages from here.
  #
  # config.before_action :do_something_awesome

  config.before_action :track_event
  def track_event
    project_id = ENV["HOST_URL"].split("-")[1]
    case params[:controller]
    when "admin/dashboard"
      call_event('freemium_panel_accessed') if params[:action] == 'index'
    when "admin/profiles"
      case params[:action]
      when 'edit'
        call_event('edit_profile_clicked')
      when 'update'
        call_event('update_profile_cta_clicked')
      when 'show'
        call_event('profile_viewed')
      end
    when 'admin/orders'
      case params[:action]
      when 'index'
        call_event('orders_accessed', properties: { action_taken: 'Invoice, Edit' })
      when 'create'
        call_event('order_placed')
      end
    when 'admin/order_statuses'
      call_event('order_status_viewed')
    when 'admin/order_report'
      call_event('order_report_viewed')
    when 'admin/products'
      case params[:action]
      when 'index'
        call_event('products_accessed', properties: { action_taken: 'View, Edit, Delete' })
      when 'create'
        call_event('new_product_created')
      when 'edit'
        call_event('new_product_edited')
      when 'update'
        call_event('new_product_updated')
      when 'delete'
        call_event('new_product_deleted')
      end
    when 'admin/accounts'
      case params[:action]
      when 'index'
        call_event('customers_accessed', properties: { action_taken: 'View, Edit, Delete' })
      when 'create'
        call_event('new_account_created')
      end
    when 'admin/coupons'
      case params[:action]
      when 'index'
        call_event('promotions_accessed', properties: { action_taken: 'View, Edit, Delete' })
      when 'create'
        call_event('new_coupon_created')
      when 'update'
        call_event('coupon_updated')
      when 'delete'
        call_event('coupon_deleted')
      end
    when 'admin/help_centers'
      case params[:action]
      when 'index'
        call_event('static_pages_accessed')
      when 'create'
        call_event('help_centre_created')
      when 'update'
        call_event('help_centre_updated')
      when 'delete'
        call_event('help_centre_deleted')
      end
    when 'admin/brand_settings'
      case params[:action]
      when 'new'
        call_event('create_new_brand_settings_initiated')
      when 'create'
        call_event('brand_settings_created')
      when 'edit'
        call_event('edit_brand_settings_cta_clicked')
      when 'update'
        call_event('brand_settings_updated')
      when 'show'
        settings_name = BxBlockStoreProfile::BrandSetting.last&.heading
        call_event('brand_settings_viewed', settings_name: settings_name)
      when 'download'
        if params[:play_store] == 'true'
          call_event('sample_play_store_requirement')
        elsif params[:play_store] == 'false'
          call_event('sample_app_requirement_clicked')
        end
      end
    when 'admin/default_email_settings'
      case params[:action]
      when 'create'
        call_event('default_email_settings_created')
      when 'update'
        call_event('default_email_settings_updated')
      when 'delete'
        call_event('email_settings_deleted', settings_type: 'Default')
      end
    when 'admin/app_banners', 'admin/web_banners', 'admin/sub_admins', 'admin/email_settings'
      feature_name = params[:controller].split('/').last
      case params[:action]
      when 'index'
        if feature_name == 'sub_admins'
          call_event("#{feature_name}_accessed", properties: { action_taken: 'View, Edit, Delete' })
        end
      when 'new'
        call_event("create_new_#{feature_name[0...-1]}_initiated")
      when 'create'
        call_event("#{feature_name[0...-1]}_created")
      when 'edit'
        call_event("#{feature_name[0...-1]}_edited")
      when 'update'
        call_event("#{feature_name[0...-1]}_updated")
      when 'delete'
        unless feature_name == 'email_settings'
          call_event("#{feature_name[0...-1]}_deleted")
        else
          call_event('email_settings_deleted', settings_type: 'Email')
        end
      end
    when 'admin/faqs', 'admin/tags', 'admin/variants', 'admin/brands', 'admin/categories', 'admin/zipcodes', 'admin/shipping_charges'
      feature_name = params[:controller].split('/').last
      case params[:action]
      when 'index'
        unless %w[variants brands shipping_charges].include?(feature_name)
          call_event("#{feature_name}_accessed", properties: { action_taken: 'View, Edit, Delete' })
        end
      when 'new'
        if feature_name == 'shipping_charges'
          call_event("create_new_#{feature_name[0...-1]}_initiated")
        elsif feature_name != 'zipcodes'
          call_event("new_#{feature_name[0...-1]}_initiated")
        end
      when 'create'
        call_event("new_#{feature_name[0...-1]}_created")
      when 'edit'
        call_event("#{feature_name[0...-1]}_edited")
      when 'update'
        call_event("#{feature_name[0...-1]}_updated")
      when 'delete'
        call_event("#{feature_name[0...-1]}_deleted")
      when 'upload_category_csv'
        call_event("#{feature_name}_uploaded")
      end
    when 'admin/taxes'
      case params[:action]
      when 'index'
        call_event("taxes_accessed")
      when 'new'
        call_event("create_new_tax_inititated")
      when 'create'
        call_event("new_tax_created")
      end
    when 'admin/api_configurations', 'admin/push_notifications'
      feature_name = params[:controller].split('/').last[0...-1]
      case params[:action]
      when 'index'
        call_event('push_notifications_accessed') if feature_name == 'push_notification'
      when 'new'
        call_event("new_#{feature_name}_initiated")
      when 'create'
        call_event("new_#{feature_name}_created")
      when 'edit'
        call_event("new_#{feature_name}_edited")
      when 'update'
        call_event("new_#{feature_name}_updated")
      when 'delete'
        call_event("new_#{feature_name}_deleted")
      end
    when 'admin/customer_feedbacks', 'admin/app_requirements'
      feature_name = params[:controller].split('/').last
      case params[:action]
      when 'index'
        call_event("#{feature_name}_accessed")
      when 'new'
        call_event("new_#{feature_name[0...-1]}_initiated")
      when 'create'
        call_event("new_#{feature_name[0...-1]}_created")
      when 'edit'
        call_event("#{feature_name[0...-1]}_edited")
      when 'update'
        call_event("#{feature_name[0...-1]}_updated")
      when 'delete'
        call_event("#{feature_name[0...-1]}_deleted") if feature_name == 'customer_feedbacks'
      end
    when 'admin/app_submission_requirements'
      case params[:action]
      when 'index'
        call_event('app_submission_requirment_accessed')
      when 'new'
        call_event('new_app_submission_initiated')
      when 'create'
        call_event('new_app_submission_created')
      when 'edit'
        call_event('app_submission_requirement_edited')
      when 'update'
        call_event('app_submission_requirement_updated')
      when 'delete'
        call_event('app_submission_requirement_deleted')
      when 'save_request'
        call_event('app_submission_requirement_request_saved')
      end
    when 'admin/qr_codes'
      case params[:action]
      when 'index'
        call_event('generate_app_store_qr_accessed')
      when 'new'
        call_event('new_app_store_qr_initiated')
      when 'create'
        call_event('new_app_store_qr_generated')
      when 'edit'
        call_event('new_app_store_qr_edited')
      when 'update'
        call_event('new_app_store_qr_updated')
      when 'delete'
        call_event('new_app_store_qr_deleted')
      end
    end
  end

  def call_event(event, properties: nil, settings_name: nil, settings_type: nil)
    project_id = ENV["HOST_URL"].split("-")[1]
    project_type = ENV["PROJECT_TYPE"]
    user_email = current_admin_user&.email
    if properties.nil? && settings_name.nil?
      Analytics.track(user_id: user_email, buildcard_id: project_id, buildcard_type: project_type, event: event)
    elsif properties.present?
      Analytics.track(user_id: user_email, buildcard_id: project_id, buildcard_type: project_type, event: event,
                      properties: properties)
    elsif settings_name.present?
      Analytics.track(user_id: user_email, buildcard_id: project_id, buildcard_type: project_type, event: event,
                      settings_name: settings_name)
    elsif settings_type.present?
      Analytics.track(user_id: user_email, buildcard_id: project_id, buildcard_type: project_type, event: event,
                      settings_type: settings_type)
    end
  end

  # == Attribute Filters
  #
  # You can exclude possibly sensitive model attributes from being displayed,
  # added to forms, or exported by default by ActiveAdmin
  #
  config.filter_attributes = [:encrypted_password, :password, :password_confirmation]

  # == Localize Date/Time Format
  #
  # Set the localize format to display dates and times.
  # To understand how to localize your app with I18n, read more at
  # https://guides.rubyonrails.org/i18n.html
  #
  # You can run `bin/rails runner 'puts I18n.t("date.formats")'` to see the
  # available formats in your application.
  #
  config.localize_format = :long

  # == Setting a Favicon
  #
  # config.favicon = 'favicon.ico'

  # == Meta Tags
  #
  # Add additional meta tags to the head element of active admin pages.
  #
  # Add tags to all pages logged in users see:
  #   config.meta_tags = { author: 'My Company' }

  # By default, sign up/sign in/recover password pages are excluded
  # from showing up in search engine results by adding a robots meta
  # tag. You can reset the hash of meta tags included in logged out
  # pages:
  #   config.meta_tags_for_logged_out_pages = {}

  # == Removing Breadcrumbs
  #
  # Breadcrumbs are enabled by default. You can customize them for individual
  # resources or you can disable them globally from here.
  #
  # config.breadcrumb = false

  # == Create Another Checkbox
  #
  # Create another checkbox is disabled by default. You can customize it for individual
  # resources or you can enable them globally from here.
  #
  # config.create_another = true

  # == Register Stylesheets & Javascripts
  #
  # We recommend using the built in Active Admin layout and loading
  # up your own stylesheets / javascripts to customize the look
  # and feel.
  #
  # To load a stylesheet:
  #   config.register_stylesheet 'my_stylesheet.css'
  config.register_stylesheet 'custom_admin.css'
  config.register_javascript 'active_admin/custom.js'
  config.register_javascript 'active_admin/cropper.js'
  config.register_javascript 'active_admin/cropper.min.js'
  config.register_javascript 'active_admin/custom_plugin/cropper.js'
  config.register_stylesheet 'cropper.css'
  config.register_stylesheet 'cropper.min.css'
  #
  # You can provide an options hash for more control, which is passed along to stylesheet_link_tag():
  #   config.register_stylesheet 'my_print_stylesheet.css', media: :print
  #
  # To load a javascript file:
  #   config.register_javascript 'my_javascript.js'

  # == CSV options
  #
  # Set the CSV builder separator
  # config.csv_options = { col_sep: ';' }
  #
  # Force the use of quotes
  # config.csv_options = { force_quotes: true }

  # == Menu System
  #
  # You can add a navigation menu to be used in your application, or configure a provided menu
  #
  # To change the default utility navigation to show a link to your website & a logout btn
  #
  #   config.namespace :admin do |admin|
  #     admin.build_menu :utility_navigation do |menu|
  #       menu.add label: "My Great Website", url: "http://www.mygreatwebsite.com", html_options: { target: :blank }
  #       admin.add_logout_button_to_menu menu
  #     end
  #   end
  #
  # If you wanted to add a static menu item to the default menu provided:
  #
  #   config.namespace :admin do |admin|
  #     admin.build_menu :default do |menu|
  #       menu.add label: "My Great Website", url: "http://www.mygreatwebsite.com", html_options: { target: :blank }
  #     end
  #   end

  # == Download Links
  #
  # You can disable download links on resource listing pages,
  # or customize the formats shown per namespace/globally
  #
  # To disable/customize for the :admin namespace:
  #
  config.namespace :admin do |admin|
  #
  #     # Disable the links entirely
  #     admin.download_links = false
  #
  #     # Only show XML & PDF options
    admin.download_links = [:csv, :json]
  #
  #     # Enable/disable the links based on block
  #     #   (for example, with cancan)
  #     admin.download_links = proc { can?(:view_download_links) }
  #
  end

  # == Pagination
  #
  # Pagination is enabled by default for all resources.
  # You can control the default per page count for all resources here.
  #
  # config.default_per_page = 30
  #
  # You can control the max per page count too.
  #
  # config.max_per_page = 10_000

  # == Filters
  #
  # By default the index screen includes a "Filters" sidebar on the right
  # hand side with a filter for each attribute of the registered model.
  # You can enable or disable them for all resources here.
  #
  # config.filters = true
  #
  # By default the filters include associations in a select, which means
  # that every record will be loaded for each association (up
  # to the value of config.maximum_association_filter_arity).
  # You can enabled or disable the inclusion
  # of those filters by default here.
  #
  config.include_default_association_filters = false

  # config.maximum_association_filter_arity = 256 # default value of :unlimited will change to 256 in a future version
  # config.filter_columns_for_large_association = [
  #    :display_name,
  #    :full_name,
  #    :name,
  #    :username,
  #    :login,
  #    :title,
  #    :email,
  #  ]
  # config.filter_method_for_large_association = '_starts_with'

  # == Head
  #
  # You can add your own content to the site head like analytics. Make sure
  # you only pass content you trust.
  #
  # config.head = ''.html_safe

  # == Footer
  #
  # By default, the footer shows the current Active Admin version. You can
  # override the content of the footer here.
  #
  # config.footer = 'my custom footer text'

  # == Sorting
  #
  # By default ActiveAdmin::OrderClause is used for sorting logic
  # You can inherit it with own class and inject it for all resources
  #
  # config.order_clause = MyOrderClause

  # == Webpacker
  #
  # By default, Active Admin uses Sprocket's asset pipeline.
  # You can switch to using Webpacker here.
  #
  # config.use_webpacker = true
  config.namespace :admin do |admin|
    admin.build_menu do |menu|
      menu.add :label => "<i class='fa fa-cog gray-icon'></i> Settings".html_safe, priority: 7, html_options: { class: 'gray-icon' } do |submenu|
        brand_setting = BxBlockStoreProfile::BrandSetting.last
        routes = Rails.application.routes.url_helpers
        submenu.add :label => "<i class='fa fa-store gray-icon'></i> Store Profile".html_safe, priority: 1 do |sb|
          sb.add :label => "Brand Setting".html_safe, priority: 1, :url => routes.admin_brand_settings_path, html_options: { class: 'nested_menu test brand-settings-nav' }
          sb.add :label => 'Email Templates', priority: 2, :url => routes.admin_email_settings_path, html_options: { class: 'nested_menu email-templates-nav' }
          sb.add :label => 'Store Admins', priority: 3, :url => routes.admin_sub_admins_path, html_options: { class: 'nested_menu' }
          sb.add :label => 'App Banners', priority: 4, :url => routes.admin_app_banners_path, html_options: { class: 'nested_menu app-banners-nav' }
          sb.add :label => 'Web Banners', priority: 5, :url => routes.admin_web_banners_path, html_options: { class: 'nested_menu web-banners-nav' }
          sb.add :label => 'Faqs', priority: 6, :url => routes.admin_faqs_path, html_options: { class: 'nested_menu' }
        end
        submenu.add :label => "<i class='fa fa-cog gray-icon'></i> Product Setting".html_safe, priority: 2 do |sb|
          sb.add :label => 'Tags',priority: 1, :url => routes.admin_tags_path, html_options: { class: 'nested_menu' }
          sb.add :label => 'Variants',priority: 2, :url => routes.admin_variants_path, html_options: { class: 'nested_menu variants-nav' }
          sb.add :label => 'Brands', priority: 3, :url => routes.admin_brands_path, html_options: { class: 'nested_menu brands-nav' }
          sb.add :label => 'Categories', priority: 4, :url => routes.admin_categories_path, html_options: { class: 'nested_menu' }
          sb.add :label => 'Bulk Upload', priority: 5, :url => routes.admin_bulk_uploads_path, html_options: { class: 'nested_menu' }
        end
        submenu.add :label => "<i class='fa fa-cog gray-icon'></i> Business Setting".html_safe, priority: 3 do |sb|
          sb.add :label => 'Taxes', priority: 1, :url => routes.admin_taxes_path, html_options: { class: 'nested_menu taxes-nav' }
          sb.add :label => 'Zipcodes', priority: 2, :url => routes.admin_zipcodes_path, html_options: { class: 'nested_menu' }
          sb.add :label => 'Shipping charges', priority: 3, :url => routes.admin_shipping_charges_path, html_options: { class: 'nested_menu shipping_charges-nav' }
          sb.add :label => 'Partner Configurations', priority: 4, :url => routes.admin_partner_configurations_path, html_options: { class: 'nested_menu partner_configurations-nav' }
          sb.add :label => 'App Requirement', priority: 5, :url => routes.admin_app_requirements_path, html_options: { class: 'nested_menu' }
          sb.add :label => "App Submission Requirement", priority: 6, :url => routes.admin_app_submission_requirements_path, html_options: { class: 'nested_menu' }
          sb.add :label => 'Generate App Store QR', priority: 7, :url => routes.admin_qr_codes_path, html_options: { class: 'nested_menu' }
          sb.add :label => 'Customer Feedback', priority: 8, :url => routes.admin_customer_feedbacks_path, html_options: { class: 'nested_menu' }
          sb.add :label => 'Push Notification', priority: 9, :url => routes.admin_push_notifications_path, html_options: { class: 'nested_menu' }
          sb.add :label => 'States', priority: 10, :url => routes.admin_states_path, html_options: { class: 'nested_menu' }
        end
        submenu.add :label => "<i class='fa fa-step-forward'></i> Onboarding".html_safe, priority: 4, url: routes.admin_onboardings_path, html_options: { class: 'nested_menu onboarding_menu' }
      end
    end

    admin.build_menu do |menu|
      menu.add :label => "<i class='fas fa-store gray-icon'></i> Preview Website<i class='fa fa-external-link-alt preview-external-link'></i>".html_safe, url: BxBlockDashboard::Dashboard.production_server_url, priority: 8, html_options: { class: 'gray-icon preview-website', target: :blank }
    end
  end

  config.namespace :admin do |admin|
    admin.build_menu :utility_navigation do |menu|
      admin.add_logout_button_to_menu menu
    end
  end
end

class ActiveAdmin::Devise::SessionsController
  # def after_sign_in_path_for(resource)
  #   brand_setting = BxBlockStoreProfile::BrandSetting.last
  #   if brand_setting.blank? && resource.super_admin?
  #     new_admin_brand_setting_path
  #   else
  #     super
  #   end
  # end

  def destroy
    project_id = ENV["HOST_URL"].split("-")[1]
    project_type = ENV["PROJECT_TYPE"]
    user_email = current_admin_user&.email
    Analytics.track(user_id: user_email, buildcard_id: project_id, buildcard_type: project_type, event: 'logout_icon_clicked')
    super
  end
end
