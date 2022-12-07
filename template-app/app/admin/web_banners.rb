module WebBanners
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

unless WebBanners::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockBanner::Banner, as: "Web Banners" do
    menu false
    permit_params :banner_position,:web_banner,
    attachments_attributes: [
      :id,
      :image,
      :position,
      :title,
      :subtitle,
      :url,
      :url_type,
      :url_id,
      :category_url_id,
      :_destroy
    ]
    remove_filter :attachments
    config.sort_order = "banner_position_desc"
    config.batch_actions = false

    index do
      selectable_column
      id_column
      column :banner_position
      column :created_at
      column :updated_at
      actions
    end

    show do |banner|
      attributes_table do
        row :banner_position
        row :created_at
        row :updated_at
      end
    end

    form do |f|
      render partial: "admin/email_settings/description.html.erb",locals: { title: 'Create your store - Web banner', subtitle: 'Add a web banner - this will go on your website’s home page.' }
      f.inputs do
        f.input :banner_position, as: :select, collection: [1,2,3,4,5], input_html: { class: 'hint_web_banner_image' }, :hint => image_tag("/assets/banner_position_#{f.object.banner_position}.png", class: "banner_inline_hint", style:"width:60px !important")
        f.has_many :attachments, as: :attachable, heading: 'Banner Images',allow_destroy: true,new_record: 'Add Image', class: "banner_image" do |i|
          i.input :position
          i.input :image, as: :file, hint: i.object.image.present? ? image_tag(i.object.image, :size => "260x180") : content_tag(:span, 'Minimum 375 height is required, Minimum 200 width is required'), input_html: { class: 'image banner-image' }
          i.input :url
        end
      end
      f.actions
    end

    controller do

      def create
        params[:banner][:web_banner] = true
        super do
          if resource.valid?
            flash[:notice] = t('messages.success.created', resource: 'Banner')
            redirect_to admin_web_banners_url and return
          else
            flash.now[:error] = "#{resource.errors.full_messages.to_sentence}"
            render action: 'edit' and return
          end
        end
      end

      def update
        super do
          if resource.valid?
            flash[:notice] = t('messages.success.updated', resource: 'Banner')
            redirect_to edit_admin_web_banner_path(resource) and return
          else
            flash.now[:error] = "#{resource.errors.full_messages.to_sentence}"
            render action: 'edit' and return
          end
        end
      end

      def destroy
        super do
          flash[:notice] = t('messages.success.deleted', resource: 'Banner')
          redirect_to(admin_web_banners_url) and return
        end
      end

      def scoped_collection
        super.where("web_banner = ?", true)
      end
    end
  end
end
