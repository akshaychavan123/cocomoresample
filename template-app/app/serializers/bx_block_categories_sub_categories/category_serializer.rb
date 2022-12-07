# == Schema Information
#
# Table name: categories
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
module BxBlockCategoriesSubCategories
  class CategorySerializer < BuilderBase::BaseSerializer
    attributes :id, :name, :created_at, :updated_at

    attribute :product_image do |object, params|
      if object.image.attached?
          {
            id: object.image.id,
            url: url_for(object.image)
          }
      else
        # Todo
        # remote urls not working so using global url for now. Uncomment when fixed by devops team
        # { url: $hostname + '/default-images/category-default.png' }
        { url: 'https://static.thenounproject.com/png/2426188-200.png' }
      end
    end

    attribute :sub_categories, if: Proc.new { |record, params|
      params && params[:sub_categories] == true
    }
  end
end
