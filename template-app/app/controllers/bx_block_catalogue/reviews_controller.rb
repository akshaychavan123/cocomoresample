module BxBlockCatalogue
  class ReviewsController < ApplicationController
    before_action :get_product, only: [:get_product_reviews]
    before_action :get_user, only: %i[create update]
    before_action :get_review, only: [:update]

    def create
      order = @current_user.orders.find_by(id: params[:order_id])
      catalogue = BxBlockCatalogue::Catalogue.active.find_by(id: params[:catalogue_id])
      order_item = BxBlockOrderManagement::OrderItem.find_by(id: params[:order_item_id])
      review = @current_user.reviews.new(review_params)
      if order.present? || order_item.present? || catalogue.present?
        if order_item.present?
          review.order_item = order_item
          review.catalogue = order_item.catalogue
        end
        if catalogue.present?
          review.catalogue = catalogue
        end
        if review.save
          render json: ReviewSerializer.new(review).serializable_hash,
                 status: :ok
        else
          render json: {
            errors: format_activerecord_errors(review.errors),
          }, status: :unprocessable_entity
        end
      else
        render json: {
          errors: [{
                     review: 'Not found any order or order item.',
                   }],
        }, status: :unprocessable_entity
      end
    end

    def index
      serializer = ReviewSerializer.new(Review.all.where(is_published: true).order(created_at: :desc))

      render json: serializer, status: :ok
    end

    def get_product_reviews
      render(
        json: { message: "No related catalogue found!" }, status: 400
      ) && return if @catalogue.nil?

      reviews = @catalogue.reviews.where(is_published: true).order(created_at: :desc)
      if reviews.present?
        render json: ReviewSerializer.new(reviews).serializable_hash,
               status: 200
      else
        render(json: { message: "No review found" }, status: 200) && return
      end
    end

    def update
      render(
        json: { message: "You have not submitted any reviews yet!" }, status: 400
      ) && return if @user_review.nil?

      if @user_review.update(
        rating: params[:rating],
        comment: params[:comment]
      )
        render json:
                 {
                   review: ReviewSerializer.new(@user_review).serializable_hash
                 }, status: 200
      else
        render json: { message: "Something went wrong. Changes not saved!" }, status: 400
      end
    end

    private

    def get_product
      @catalogue = Catalogue.active.find_by(id: params[:id])
    end

    def get_review
      @user_review = @current_user.reviews.where(is_published: true).find_by(id: params[:id])
    end

    def review_params
      params.permit(:order_id, :comment, :rating, :catalogue_id, :order_item_id)
    end

    def format_activerecord_errors(errors)
      result = []
      errors.each do |attribute, error|
        result << { attribute => error }
      end
      result
    end
  end
end
