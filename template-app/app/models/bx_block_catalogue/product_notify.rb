module BxBlockCatalogue
  class ProductNotify < BxBlockCatalogue::ApplicationRecord
    self.table_name = :product_notifies

    belongs_to :account, class_name: "AccountBlock::Account"
    belongs_to :catalogue_variant, optional: true
    belongs_to :catalogue, optional: true
  end
end
