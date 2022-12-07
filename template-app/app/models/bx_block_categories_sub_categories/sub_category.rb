# == Schema Information
#
# Table name: sub_categories
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
module BxBlockCategoriesSubCategories
  class SubCategory < BxBlockCategoriesSubCategories::ApplicationRecord
    self.table_name = :sub_categories

    attr_accessor :from_csv

    # validates :name, uniqueness: { scope: :category_id,
    # message: "Sub Category name should not be same" }

    validates_uniqueness_of :name, scope: :category_id

    has_one_attached :image

    validates :image, attached: true, content_type: ['image/png', 'image/jpg', 'image/jpeg'], if: -> (sub_category) { Rails.env != 'test' && sub_category.from_csv != true }
    validate :validate_image, if: -> (sub_category) { Rails.env != 'test' && sub_category.from_csv != true }

    has_and_belongs_to_many :catalogues, class_name: 'BxBlockCatalogue::Catalogue', join_table: 'catalogues_sub_categories', foreign_key: 'sub_category_id'

    belongs_to :category

    after_save :update_disabled

    def update_disabled
      self.update_column(:disabled, true) if self.category.disabled?
    end

    private

    def validate_image
      image_size = FastImage.size(self.attachment_changes['image'].attachable) rescue nil
      return true unless image_size.present?
      if (image_size[0] < 120 || image_size[0] > 800) || (image_size[1] < 120 || image_size[1] > 800)
        errors.add(:image, "The selected file could not be uploaded. The minimum dimensions are 120x120 pixels. The maximum dimensions are 800x800 pixels.")
      end
    end
  end
end
