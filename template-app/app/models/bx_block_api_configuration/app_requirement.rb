module BxBlockApiConfiguration
  class AppRequirement < ApplicationRecord
    self.table_name = :app_requirements
    has_one_attached :file

    validates :requirement_type, uniqueness: true
    validates :file, presence: true

    enum requirement_type: ['play store', 'app']
  end
end
