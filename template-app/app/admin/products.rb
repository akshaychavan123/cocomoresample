module Products
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

unless Products::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockCatalogue::Catalogue, as: "Products" do
    menu priority: 3, :label=> "<i class='fa fa-warehouse gray-icon'></i> Products".html_safe

    permit_params :brand_id, :name, :sku, :description, :manufacture_date, :length, :breadth, :height, :availability, :stock_qty, :tax_id,
                  :weight, :price, :recommended, :status, :on_sale,  :sale_price, :discount, :created_at, :updated_at, :block_qty, :_destroy,
                  :sold, {:sub_category_ids => []}, attachments_attributes: [
      :id,
      :image,
      :cropped_image,
      :position,
      :is_default,
      :_destroy
    ], tag_ids: [],
    catalogue_variants_attributes: [
      :id,
      :catalogue_id,
      :price,
      :stock_qty,
      :on_sale,
      :sale_price,
      :discount_price,
      :length,
      :breadth,
      :height,
      :created_at,
      :updated_at,
      :block_qty,
      :tax_id,
      :is_default,
      :_destroy,
      catalogue_variant_properties_attributes: [
        :id,
        :variant_id,
        :variant_property_id,
        :_destroy
      ],
      attachments_attributes: [
        :id,
        :image,
        :cropped_image,
        :position,
        :is_default,
        :_destroy
      ]
    ], catalogue_subscriptions_attributes: [:id, :subscription_package, :subscription_period, :discount, :morning_slot, :evening_slot, :_destroy, morning_slot: [], evening_slot: []]

    skip_before_filter :verify_authenticity_token, only: :change_variant_properties

    batch_action :destroy, confirm: "Are you sure you want to delete these products?" do |ids|
      if BxBlockCatalogue::Catalogue.where(id:ids).destroy_all
        flash[:notice]= "Successfully deleted #{ids.count} products"
      else
        flash[:alert]= "Unable to delete products"
      end

      redirect_to collection_path
    end

    scope :all
    scope :latest
    scope :popular

    filter :brand
    filter :name
    filter :sku
    filter :availability

    index do
      selectable_column
      id_column
      column :name
      column :sku
      column :category do |prod|
        cat_ids = prod.sub_categories.pluck(:category_id).uniq
        BxBlockCategoriesSubCategories::Category.where(id: cat_ids).pluck(:name).join(", ")
      end
      column :sub_category do |prod|
        sub_cat_ids = prod.sub_categories.pluck(:name).uniq.join(", ")
      end
      column :stock_qty
      column :block_qty
      column :price
      column :sold
      column 'Active' do |c|
        label class: "switch" do
          input id: "catalogue-active-switch-#{c.id}", type: "radio", 'data-id': c.id, checked: c.active?
          span class: "slider round catalogue-active-span", 'data-id': c.id
        end
      end
      actions
    end

    show do |catalogue|
      attributes_table do
        row "Category" do |a|
          links = []
          a.sub_categories.distinct.each do |cat|
            links << (link_to cat.category.name, admin_category_path(cat.category.id))
          end
          links.join(", ").html_safe
        end
        row "SubCategory" do |a|
          links = []
          a.sub_categories.distinct.each do |cat|
            links << cat.name
          end
          links.join(", ").html_safe
        end
        row :brand
        row :tags
        row :name
        row :sku
        # row :hsn_code
        row :description
        row :manufacture_date
        row :length
        row :breadth
        row :height
        row :availability
        row :stock_qty
        row :weight
        row :price
        row :on_sale
        row :sale_price
        row :recommended
        row :block_qty
        row :sold
        row :discount
        row :created_at
        row :updated_at
        row :status
        row 'images' do |c|
          c.attachments.each do |attachment|
            div :class => "col-xs-4" do
              image_tag(url_for(attachment.image)) rescue nil if attachment.present?
            end
          end
        end
        panel "Product Variants" do
          table_for catalogue.catalogue_variants do
            column "Id" do |cv|
              cv.id
            end
            BxBlockCatalogue::Variant.all.each do |variant|
              column variant.name do |catalogue_variant|
                catalogue_variant.catalogue_variant_properties&.where(variant_id: variant.id)&.last&.variant_property&.name
              end
            end
            column "Price" do |cv|
              cv.price
            end
            column "Stock Quantity" do |cv|
              cv.stock_qty
            end
            column "On Sale" do |cv|
              cv.on_sale
            end
            column "Sale Price" do |cv|
              cv.sale_price
            end
            column "Discount Price" do |cv|
              cv.discount_price
            end
            column "Length" do |cv|
              cv.length
            end
            column "Breadth" do |cv|
              cv.breadth
            end
            column "Height" do |cv|
              cv.height
            end
            column "Block Quantity" do |cv|
              cv.block_qty
            end
            column "Default" do |cv|
              cv.is_default
            end
            column "created_at" do |cv|
              cv.created_at
            end
            column "updated_at" do |cv|
              cv.updated_at
            end
            column :images do |cv|
              cv.attachments.each do |attachment|
                div :class => "col-xs-4" do
                  image_tag(url_for(attachment.image)) if attachment.present?
                end
              end
            end
          end
        end
      end
    end

    form :html => {:multipart => true} do |f|
      f.object.weight = f.object.weight.present? && f.object.weight > 0  ? f.object.weight : 1.0 if f.object.present?
      f.inputs do
        f.input :sub_categories, label: "Categories", as: :select,
                collection: option_groups_from_collection_for_select(BxBlockCategoriesSubCategories::Category.all, :sub_categories, :name, :id, :name, f.object.sub_categories.ids),
                allow_blank: false, multiple: true, input_html: { }
        f.input :brand_id, as: :select, collection: BxBlockCatalogue::Brand.all.map { |u| [u.name, u.id] }, :prompt => "Select Brand"
        f.input :tags, as: :select, collection: BxBlockCatalogue::Tag.all.map { |u| [u.name, u.id] }, :prompt => "Select Tag"
        f.input :name
        f.input :sku
        # f.input :hsn_code
        f.input :description, as: :ckeditor
        f.input :manufacture_date, as: :date_time_picker
        f.input :length, label: "Length (Will be used for shipping)"
        f.input :breadth, label: "Breadth (Will be used for shipping)"
        f.input :height, label: "Height (Will be used for shipping)"
        f.input :availability
        f.input :stock_qty
        f.input :weight
        f.input :price, input_html: { class: 'product_price' }
        f.input :on_sale, input_html: { class: 'on_sale' }
        f.input :sale_price, label: "Discounted Price", input_html: { class: 'sale_price' }
        f.input :recommended
        f.input :block_qty
        f.input :sold
        f.input :discount, input_html: { class: 'discount', readonly: true }
        f.input :tax_id, label: 'Tax', as: :select, collection: BxBlockOrderManagement::Tax.all.map { |t| [t.tax_percentage, t.id] }, include_blank: false, :prompt => "Select Tax"
        f.input :tax_amount, input_html: { disabled: true }
        # f.input :price_including_tax, input_html: { disabled: true }
        f.input :status
        f.has_many :attachments, as: :attachable, heading: 'Images', allow_destroy: true,
                   new_record: 'Add Image' do |i|
          i.input :image, as: :file,:label => "Image", hint: i.object.image.present? ? image_tag(i.object.image, :size => "260x180", class: 'preview') : content_tag(:span, ''), input_html: { class: 'image cropper custom-file-inputproduct', 'cropped-image-temp-store-id': "#croppedImageTempStoreProduct-#{i.index}" }

          i.input :cropped_image, :as => :hidden, input_html: {class: 'cropped-product-image-hidden-field', id: "croppedImageTempStoreProduct-#{i.index}"}
          i.input :is_default, as: :boolean
        end
        div do
          render partial: 'new'
        end
        div do
          render partial: 'button'
        end

        if f.object.catalogue_subscriptions.blank?
          f.has_many :catalogue_variants, heading: 'Product Variants',allow_destroy: true, new_record: 'Add Variant', class: "pv_panel" do |pv|
            pv.has_many :catalogue_variant_properties, heading: '', allow_destroy: true, new_record: 'Add New Variants' do |ca|
              if ca.object.present? && ca.object.new_record?
                ca.input :variant, collection: BxBlockCatalogue::Variant.all.map { |u| [u&.name, u.id] }, include_blank: true, input_html: { :onchange => remote_request(:post, :change_variant_properties, {:variant_id=>"$(this).val()", element_id: '$(this).attr("id")'}, :variant_property_id)
                }
              else
                ca.input :variant, collection: BxBlockCatalogue::Variant.all.map { |u| [u&.name, u.id] }, include_blank: false, input_html: { class: 'variant select2', disabled: true, :onchange => remote_request(:post, :change_variant_properties, {:variant_id=>"$(this).val()", element_id: '$(this).attr("id")'}, :variant_property_id)
                }
              end
              if ca.object.present? && ca.object.persisted?
                options = ca.object.variant.variant_properties
              else
                options = BxBlockCatalogue::VariantProperty.all
              end
              ca.input :variant_property, :label => "Variant Property", collection: options.map { |u| [u&.name, u.id,  {"data-variant" => u.variant_id}] }, include_blank: false, input_html: { class: "attribute_value1 select2" }
            end
            pv.input :price, label: "Price", input_html: { class: 'product_price' }
            pv.input :stock_qty
            pv.input :on_sale, input_html: { class: 'on_sale' }
            pv.input :sale_price, input_html: { class: 'sale_price' }
            pv.input :discount_price, input_html: { class: 'discount', readonly: true  }
            pv.input :tax_id, label: 'Tax', as: :select, collection: BxBlockOrderManagement::Tax.all.map { |t| [t.tax_percentage, t.id] }, include_blank: false, :prompt => "Select Tax"
            pv.input :tax_amount, input_html: { disabled: true }
            pv.input :price_including_tax, input_html: { disabled: true }
            pv.input :length
            pv.input :breadth
            pv.input :height
            pv.input :block_qty
            pv.input :updated_at, :input_html => { :value => DateTime.current }, as: :hidden
            pv.input :is_default

            pv.has_many :attachments, as: :attachable, heading: 'Images',allow_destroy: true,new_record: 'Add Image' do |i|
              i.input :image, as: :file, hint: i.object.image.present? ? image_tag(i.object.image, :size => "260x180", class: 'preview') : content_tag(:span, ''), input_html: { class: 'image cropper custom-file-inputproduct', 'cropped-image-temp-store-id': "#croppedImageTempStoreVariants-#{pv.index}-#{i.index}" }
              i.input :cropped_image, :as => :hidden, input_html: {class: 'cropped-product-image-hidden-field', id:"croppedImageTempStoreVariants-#{pv.index}-#{i.index}"}
              i.input :is_default
              i.button "Filter"
            end
          end
        end

        if f.object.catalogue_variants.blank?
          f.has_many :catalogue_subscriptions, heading: 'Product Subscription',allow_destroy: true, new_record: 'Add Subscription', class: "ps_panel" do |ps|
            ps.input :subscription_package, as: :select, collection: BxBlockCatalogue::CatalogueSubscription::SUBSCRIPTION_PACKAGE.map { |sp| [sp.capitalize, sp] }, include_blank: true, allow_blank: false, :prompt => "Select Package"
            ps.input :subscription_period, as: :select, collection: BxBlockCatalogue::CatalogueSubscription::SUBSCRIPTION_PERIOD.map { |sp| ["#{sp.capitalize} month", sp] }, include_blank: true, allow_blank: false, :prompt => "Select Period"
            ps.input :discount, label: 'Discount%', input_html: { class: 'subscription_discount' }
            if ps.object.new_record?
              ps.input :morning_slot, label: 'Delivery Time(Morning Slot)', as: :select, multiple: true, collection: BxBlockCatalogue::CatalogueSubscription::MORNING_SLOTS.map{|es| [es.humanize.upcase, es]}
              ps.input :evening_slot, label: 'Delivery Time(Evening Slot)', as: :select, multiple: true, collection: BxBlockCatalogue::CatalogueSubscription::EVENING_SLOTS.map{|es| [es.humanize.upcase, es]}
            else
              m_slot = JSON.parse(ps.object.morning_slot).select{|m| m.present?}
              e_slot = JSON.parse(ps.object.evening_slot).select{|m| m.present?}
              ps.input :morning_slot, label: 'Delivery Time(Morning Slot)', as: :select, collection: BxBlockCatalogue::CatalogueSubscription::MORNING_SLOTS.map{|es| [es.humanize.upcase, es]}, multiple: true,input_html: { value: m_slot, class: "remove-select2-hidden-accessible" }
              ps.input :evening_slot, label: 'Delivery Time(Evening Slot)', as: :select, multiple: true, collection: BxBlockCatalogue::CatalogueSubscription::EVENING_SLOTS.map{|es| [es.humanize.upcase, es]}, input_html: { value: e_slot, class: "remove-select2-hidden-accessible" }
            end
          end
        end
      end
      f.actions
    end

    config.clear_action_items!

    action_item :instructions, only: :upload_csv do
      link_to "Instructions", "https://intercom.help/engineerai/en/articles/6154912-csv-upload-help-guide", target: "_blank"
    end

    action_item :download_sample_file, only: :upload_csv do
      link_to('Download Sample File', download_admin_products_path())
    end

    action_item :new, only: :index do
      link_to 'New Products', { action: 'new' }, class: 'new-products'
    end

    action_item :upload_csv, only: :index do
      link_to 'Upload CSV', :action => 'upload_csv'
    end

    collection_action :download, method: :get do
      csv_string = CSV.generate do |csv|
        csv_data = BxBlockCatalogue::Catalogue.new_variant_sample_csv
        # heading
        csv << csv_data[0]
        # info
        csv << csv_data[1]

        @filename = "product_sample_file-#{Time.now.to_date.to_s}.csv"
      end
      send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => @filename)
    end

    collection_action :upload_csv do
      render "/admin/csv/upload_csv"
    end

    collection_action :import_csv, :method => :post do
      if params[:upload_csv] && params[:upload_csv][:file]
        if params[:upload_csv][:file].content_type.include?("csv")
          csv_path = "tmp/#{params[:upload_csv][:file].original_filename}"
          File.open(csv_path, 'wb') do |f|
            f.write params[:upload_csv][:file].read
          end

          BxBlockCatalogue::CatalogueCsvUploadJob.perform_later(csv_path)

          redirect_to upload_csv_admin_products_path, flash: {warning: "File upload has been started!"}
        else
          redirect_to upload_csv_admin_products_path, flash: {error: "File format not valid!"}
        end
      else
        redirect_to upload_csv_admin_products_path, flash: {error: "Please select file!"}
      end
    end

    member_action :delete_image, method: :delete do
      @pic = ActiveStorage::Attachment.find(params[:image_id])
      @pic.purge_later
      redirect_back(fallback_location: edit_admin_product_path(params[:id]))
    end

    member_action :thingy_filter, method: :patch do
      redirect_to edit_thingy_path(resource, thingy_filter: params["thingy"]["thingy_filter"])
    end

    collection_action :catalogue_sub_category_dropdown do
      cate = BxBlockCategoriesSubCategories::Category.find_by(id: params[:product_category_id])
      array = cate.sub_categories&.map { |u| {name: u.name, id: u.id} }.compact
      render :json => array.compact
    end

    controller do

      def change_variant_properties
        @variant_properties = BxBlockCatalogue::Variant.find(params[:variant_id]).try(:variant_properties)
      end

      def create
        reject_blank_images
        super do
          if resource.valid?
            flash[:notice] = t('messages.success.created', resource: 'Product')
            redirect_to admin_products_url and return
          else
            flash.now[:error] = resource.errors.full_messages.to_sentence
            render action: 'new' and return
          end
        end
      end

      def update
        # reject_blank_images
        super do
          if resource.valid?
            flash[:notice] = t('messages.success.updated', resource: 'Product')
            redirect_to edit_admin_product_path(resource) and return
          else
            flash.now[:error] = resource.errors.full_messages.to_sentence
            render action: 'edit' and return
          end
        end
      end

      def destroy
        # ActiveRecord::Base.connection.disable_referential_integrity do
        begin
          super do
            flash[:notice] = t('messages.success.deleted', resource: 'Product')
            redirect_to(admin_products_url) and return
          end
        rescue
          flash[:alert]= "Unable to delete product, as it is added in some orders"
        end
        # end
      end

      private

      def reject_blank_images
        params["catalogue"]["attachments_attributes"].select!{|k,v|
          v["cropped_image"].present? || v["_destroy"] == "1"
        } if params["catalogue"]["attachments_attributes"].present?

        if params.dig(:catalogue, :catalogue_variants_attributes).present?
          params[:catalogue][:catalogue_variants_attributes].each do |k,v|
            v['attachments_attributes'].select!{|k,v|
              v["cropped_image"].present? || v["_destroy"] == "1"
            } if v['attachments_attributes'].present?
          end
        end
      end

    end
  end
end

