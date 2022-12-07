# == Schema Information
#
# Table name: tags
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
module BxBlockCatalogue
  class Tag < BxBlockCatalogue::ApplicationRecord
    self.table_name = :tags

    validates :name, presence: true
    validates_uniqueness_of :name

    has_and_belongs_to_many :catalogue, join_table: :catalogues_tags

    accepts_nested_attributes_for :catalogue

    after_create :track_event

    def track_event
      Analytics.track(user_id: ENV["HOST_URL"].split("-")[1],event: 'New tags Created')
    end
  end
end
