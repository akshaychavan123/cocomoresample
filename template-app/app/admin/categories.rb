module Categories
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

unless Categories::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockCategoriesSubCategories::Category, as: "Category" do
    menu false
    permit_params :name, :image,:cropped_image,
    sub_categories_attributes: [
      :id,
      :name,
      :image,
      :_destroy
    ]

    filter :name, label: "Categories"
    filter :sub_categories
    # filter :created_at
    # filter :updated_at

    batch_action :disabled do |ids|
      batch_action_collection.find(ids).each do |category|
        category.update(disabled: true)
        category.sub_categories.update_all(disabled: true)
      end
      redirect_to collection_path
    end

    batch_action :enabled do |ids|
      batch_action_collection.find(ids).each do |category|
        category.update(disabled: false)
        category.sub_categories.update_all(disabled: false)
      end
      redirect_to collection_path
    end

    action_item :download_sample_file, only: :upload_category_csv do
      link_to('Download Sample File', download_admin_categories_path(), class: 'download-categories-sample-file')
    end

    collection_action :download, method: :get do
      file_name = Rails.root + "lib/category.csv"
      send_file file_name, type: "application/csv"
    end

    action_item :upload_category_csv, only: :index do
      link_to 'Upload CSV', :action => 'upload_category_csv'
    end

    collection_action :upload_category_csv do
      render "/admin/csv/upload_category_csv"
    end

    collection_action :import_csv, :method => :post do
      if params[:upload_category_csv] && params[:upload_category_csv][:file]
        if (params[:upload_category_csv][:file].content_type.include?("csv") || params[:upload_category_csv][:file].content_type.include?("excel") || params[:upload_category_csv][:file].content_type.include?("xls"))
          csv_errors = {}
          count, csv_errors = CsvDbCategory.convert_save("BxBlockCategoriesSubCategories::Category", params[:upload_category_csv][:file])
          if count > 0 || csv_errors.present?
            success_message = "#{count} categories uploaded/updated successfully. \n"
            error_message = ""
            if csv_errors.present?
              error_message += "CSV has error(s) on: \n"
              csv_errors.each do |error|
                error_message += error[0] + error[1].join(", ")
              end
            end
            redirect_to admin_categories_path, flash: {:notice => success_message, :error => error_message}
          elsif !csv_errors.empty?
            redirect_to upload_category_csv_admin_categories_path, flash[:error] = csv_errors
          else
            redirect_to upload_category_csv_admin_categories_path, flash: {error: "There is some problem with CSV. Please check sample file and upload again!"}
          end
        else
          redirect_to upload_category_csv_admin_categories_path, flash: {error: "File format not valid!"}
        end
      else
        redirect_to upload_category_csv_admin_categories_path, flash: {error: "Please select file!"}
      end
    end

    index do
      selectable_column
      id_column
      column "Category", :name
      column :disabled
      column :image do |category|
        div :class => "cat_img" do
          image_tag(url_for(category.image)) if category.image.present?
        end
      end
      column :sub_categories
      column :created_at
      column :updated_at
      actions
    end

    show do
      attributes_table do
        row :id
        row :name
        row :image do |category|
          div :class => "col-xs-4" do
            image_tag(url_for(category.image)) if category.image.present?
          end
        end
        row :created_at
        row :updated_at
        div :class => "panel" do
          h3 "Sub Categories"
          if category.sub_categories.any?
            div :class => "panel_contents" do
              div :class => "attributes_table" do
                table do
                  tbody do
                    tr do
                      th do
                        "Id"
                      end
                      th do
                        "Sub Category"
                      end
                      th do
                        "Image"
                      end
                      th do
                        "Created At"
                      end
                      th do
                        "Updated At"
                      end
                    end
                    category.sub_categories.each do |sub_cat|
                      tr do
                        td do
                          sub_cat.id
                        end
                        td do
                          sub_cat.name
                        end
                        td do
                          div :class => "col-xs-4" do
                            image_tag(url_for(sub_cat.image)) if sub_cat.image.present?
                          end
                        end
                        td do
                          sub_cat.created_at
                        end
                        td do
                          sub_cat.updated_at
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end


    form do |f|
      render partial: "admin/email_settings/description.html.erb",locals: { title: 'Add your products - Categories', subtitle: 'Tell us your product categories (and subcategories) to help organise your catalogue (eg Electronics. Clothing.'}
      f.inputs do
        f.input :name
        f.input :image, :as => :file, input_html:{class: 'cropper', id: 'categoryImage','cropped-image-temp-store-id': '#croppedImageTempStore'}, :hint => f.object.image.present? ? image_tag(url_for(f.object.image),class:"preview") : content_tag(:span, "120x120 resolution will be good")
        f.input :cropped_image, :as => :hidden, input_html: {id: 'croppedImageTempStore'}
        f.has_many :sub_categories, allow_destroy: true do |sub_category|
          sub_category.input :name
          sub_category.input :image, :as => :file, :hint => sub_category.object.image.present? ? image_tag(url_for(sub_category.object.image)) : content_tag(:span, "120x120 resolution will be good")
        end
      end
      f.actions
      div do
        render partial: 'new'
      end
    end

    controller do
      def create
        if permitted_params[:category]["sub_categories_attributes"].present?
          begin
            ActiveRecord::Base.transaction do
              cat = BxBlockCategoriesSubCategories::Category.create!(name: permitted_params[:category]["name"], image: permitted_params[:category]["image"], cropped_image: permitted_params[:category]["cropped_image"])
              permitted_params[:category]["sub_categories_attributes"].each do |k,v|
                sub_cat = cat.sub_categories.create!(v)
              end
              flash[:notice] = "Category created successfully"
              redirect_to admin_category_path(cat)
            end
          rescue Exception => error
            flash[:error] = error.message
            redirect_to new_admin_category_path
          end
        else
          super
        end
      end
    end
  end
end

