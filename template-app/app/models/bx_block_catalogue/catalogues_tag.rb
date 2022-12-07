# == Schema Information
#
# Table name: catalogues_tags
#
#  id           :bigint           not null, primary key
#  catalogue_id :bigint           not null
#  tag_id       :bigint           not null
#
module BxBlockCatalogue
  class CataloguesTag < BxBlockCatalogue::ApplicationRecord
    self.table_name = :catalogues_tags

    belongs_to :catalogue
    belongs_to :tag
  end
end
