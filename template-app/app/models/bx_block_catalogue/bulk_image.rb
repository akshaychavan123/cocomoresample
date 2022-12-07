module BxBlockCatalogue
  class BulkImage < BxBlockCatalogue::ApplicationRecord
    self.table_name = :bulk_images

    # Associations
    has_one_attached :image
    has_and_belongs_to_many :catalogues, class_name: 'BxBlockCatalogue::Catalogue',
                            join_table: 'catalogues_bulk_images', optional: true

    # Validations
    validates :image, content_type: ['image/png', 'image/jpg', 'image/jpeg'], attached: true

  end
end
