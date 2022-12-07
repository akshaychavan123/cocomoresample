module BxBlockCategoriesSubCategories
  class CategoriesController < ApplicationController
    before_action :load_category, only: [:show, :update, :destroy, :get_sub_categories]
    before_action :load_sub_categories, only: [:fetch_sub_categories]

    def create
      if params[:categories].blank? || params[:categories].size.zero?
        raise 'Wrong input data'
      end

      categories_to_create = params[:categories].map do |x|
        x.permit(:name).to_h
      end

      ActiveRecord::Base.transaction do
        @categories = Category.create!(categories_to_create)
      end

      process_image(@categories, params[:image]) if @categories

      render json: CategorySerializer.new(@categories, serialization_options).serializable_hash,
             status: :ok
    end

    def show
      return if @category.nil?

      render json: CategorySerializer.new(@category, serialization_options).serializable_hash,
             status: :ok
    end

    def index
      serializer = if params[:sub_category_id].present?
                     categories = SubCategory.find(params[:sub_category_id]).categories.latest.page(params[:page]).per(params[:per_page])
                     CategorySerializer.new(categories)
                   else
                     categories = Category.all.latest.enabled.page(params[:page]).per(params[:per_page])
                     CategorySerializer.new(categories, serialization_options)
                   end

      render json: serializer, status: :ok
    end

    def destroy
      return if @category.nil?

      begin
        if @category.destroy
          remove_not_used_subcategories

          render json: { success: true }, status: :ok
        end
      rescue ActiveRecord::InvalidForeignKey
        catalogue = "#{@category.catalogue.name} (id - #{@category.catalogue.id})"
        message = "Record can't be deleted due to reference to catalogue: #{catalogue}"

        render json: { error: { message: message } }, status: :internal_server_error
      end
    end

    def update
      return if @category.nil?

      update_result = @category.update(name: params[:category_name])

      if update_result
        process_image_update(@category, params[:image])
        render json: CategorySerializer.new(@category).serializable_hash,
               status: :ok
      else
        render json: ErrorSerializer.new(@category).serializable_hash,
               status: :unprocessable_entity
      end
    end

    def get_sub_categories
      if @category.present?
        sub_categories = @category.sub_categories
        render json: SubCategorySerializer.new(sub_categories).serializable_hash,
               status: :ok
      else
        render json: {
          success: false,
          message: "Category does not exist",
        }, status: 400
      end
    end

    def fetch_sub_categories
      render json: SubCategorySerializer.new(@sub_categories).serializable_hash,
             status: :ok
    end

    def process_image(imagable, image_params)
      return unless image_params.present?

      image_to_attach = []

      if image_params[:id].present? && (image_params[:remove].present? || image_params[:data].present?)
        image_to_remove = image_params[:id]
      end

      if image_params[:data]
        image_to_attach.push(
          io: StringIO.new(Base64.decode64(image_params[:data])),
          content_type: image_params[:content_type],
          filename: image_params[:filename]
        )
      end
      imagable.map do |category|
        category.image.where(id: image_to_remove).purge if image_to_remove.present?
      end
      imagable.map do |category|
        category.image.attach(image_to_attach.first) if image_to_attach.size.positive?
      end
    end

    def process_image_update(imagable, image_params)
      return unless image_params.present?

      image_to_attach = []

      if image_params[:id].present? && (image_params[:remove].present? || image_params[:data].present?)
        image_to_remove = image_params[:id]
      end

      if image_params[:data]
        image_to_attach.push(
          io: StringIO.new(Base64.decode64(image_params[:data])),
          content_type: image_params[:content_type],
          filename: image_params[:filename]
        )
      end

      imagable.image.where(id: image_to_remove).purge if image_to_remove.present?
      imagable.image.attach(image_to_attach.first) if image_to_attach.size.positive?
    end

    def reindex
      if Category.reindex
        render json: {
          message: "Reindexed successfully"
        }, status: 200
      else
        render json: {
          message: "Reindexing unsuccessful"
        }, status: 400
      end
    end

    def upload_category_csv
      if params[:category_csv] && params[:category_csv][:file]
        if (params[:category_csv][:file].content_type.include?("csv") || params[:category_csv][:file].content_type.include?("excel") || params[:category_csv][:file].content_type.include?("xls"))
          csv_errors = {}
          count, csv_errors = CsvDbCategory.convert_save("BxBlockCategoriesSubCategories::Category", params[:category_csv][:file])
          if count > 0 || csv_errors.present?
            success_message = "#{count} categories uploaded/updated successfully."
            error_message = ""
            if csv_errors.present?
              error_message += "CSV has error(s) on:"
              csv_errors.each do |error|
                error_message += error[0] + error[1].join(", ")
              end
              render json: {message: success_message , errors: error_message }, status: :unprocessable_entity
            else
              render json: {message: 'Category created successfully' , data: CategorySerializer.new(Category.all.latest.enabled, serialization_options).serializable_hash },
                     status: :ok
            end
          elsif !csv_errors.empty?
            render json: {errors: csv_errors }, status: :unprocessable_entity
          else
            render json: {message: 'There is some problem with CSV. Please check sample file and upload again!' }, status: :unprocessable_entity
          end
        else
          render json: {message: 'File format not valid!' }, status: :unprocessable_entity
        end
      else
        render json: {message: 'Please select file!' }, status: :unprocessable_entity
      end
    end

    private

    def load_category
      @category = Category.find_by(id: params[:id])

      if @category.nil?
        render json: {
          message: "Category with id #{params[:id]} doesn't exists"
        }, status: :not_found
      end
    end

    def load_sub_categories
      if params[:id].present?
        @sub_categories = []
        params[:id].map do |id|
          @sub_categories << SubCategory.find_by(category_id: id)
        end
      else
        @sub_categories = SubCategory.all
      end
    end

    def serialization_options
      options = {}
      options[:params] = { sub_categories: true }
      options
    end

    def remove_not_used_subcategories
      sql = "delete from sub_categories sc where sc.id in (
               select sc.id from sub_categories sc
               left join categories_sub_categories csc on sc.id = csc.sub_category_id
               where csc.sub_category_id is null
             )"
      ActiveRecord::Base.connection.execute(sql)
    end
  end
end
