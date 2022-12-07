# == Schema Information
#
# Table name: reviews
#
#  id           :bigint           not null, primary key
#  catalogue_id :bigint           not null
#  comment      :string
#  rating       :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint           not null
#
module BxBlockCatalogue
  class ReviewSerializer < BuilderBase::BaseSerializer
    attributes :id, :catalogue_id, :rating, :comment, :created_at, :updated_at,
               :account_id, :order_id
    attribute :account do |object|
      if object.present?
        AccountBlock::AccountSerializer.new(object.account).serializable_hash[:data][:attributes]
      end
    end

    attribute :review_date do |object|
      created_at = object.created_at.in_time_zone(Review::TIME_ZONE)
      created_at&.strftime("%d %b %Y")
    end

    attribute :review_datetime do |object|
      created_at = object.created_at.in_time_zone(Review::TIME_ZONE)
      created_at&.strftime("%a, #{created_at.day.ordinalize} %B %Y - %I:%M %p")
    end

    attribute :product_name do |object|
      object.catalogue&.name
    end

    attribute :user_name do |object|
      object.account&.full_name
    end
  end
end
