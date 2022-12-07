module BxBlockCategoriesSubCategories
  class SubCategoriesController < ApplicationController
    before_action :load_sub_category, only: [:show, :update, :destroy]

    def create
      if params[:sub_category].blank? || params[:sub_category][:name].blank?
        raise 'Wrong input data'
      end

      sub_category = SubCategory.create(name: params[:sub_category][:name])

      if sub_category.valid?
        if params[:parent_categories].present?
          sub_category.categories << Category.where(id: params[:parent_categories])
        end

        render json: SubCategorySerializer.new(sub_category, serialization_options).serializable_hash,
               status: :ok
      else
        render json: ErrorSerializer.new(sub_category).serializable_hash,
               status: :unprocessable_entity
      end
    end

    def show
      return if @sub_category.nil?

      render json: SubCategorySerializer.new(@sub_category).serializable_hash,
             status: :ok
    end

    def index
      serializer = if params[:category_id].present?
                     sub_categories = Category.find(params[:category_id]).sub_categories
                     SubCategorySerializer.new(sub_categories)
                   else
                     SubCategorySerializer.new(SubCategory.all, serialization_options)
                   end

      render json: serializer, status: :ok
    end

    def destroy
      return if @sub_category.nil?

      begin
        @cat_sub_cat = BxBlockCategoriesSubCategories::CategorySubCategory.where(sub_category_id: @sub_category.id)
        @cat_sub_cat.destroy_all  if @cat_sub_cat.present?
        if @sub_category.destroy
          render json: { success: true }, status: :ok
        end
      rescue ActiveRecord::InvalidForeignKey
        # puts "#{@sub_category.catalogue.to_json}"

        # catalogue = "#{@sub_category.catalogue.name} (id - #{@sub_category.catalogue.id})"
        # message = "Record can't be deleted due to reference to catalogue: #{catalogue}"

        render json: { error: { message: "Record can't be deleted" } }, status: :internal_server_error

      end
    end

    def update
      return if @sub_category.nil?

      update_result = @sub_category.update(name: params[:sub_category][:name])

      if update_result
        render json: SubCategorySerializer.new(@sub_category).serializable_hash,
               status: :ok
      else
        render json: ErrorSerializer.new(@sub_category).serializable_hash,
               status: :unprocessable_entity
      end
    end

    def reindex
      if SubCategory.reindex
        render json: {
          message: "Reindexed successfully"
        }, status: 200
      else
        render json: {
          message: "Reindexing unsuccessful"
        }, status: 400
      end
    end
    private

    def load_sub_category
      @sub_category = SubCategory.find_by(id: params[:id])

      if @sub_category.nil?
        render json: {
          message: "SubCategory with id #{params[:id]} doesn't exists"
        }, status: :not_found
      end
    end

    def serialization_options
      options = {}
      options[:params] = { categories: true }
      options
    end
  end
end
