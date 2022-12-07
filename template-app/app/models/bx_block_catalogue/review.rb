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
  class Review < BxBlockCatalogue::ApplicationRecord
    self.table_name = :reviews

    belongs_to :catalogue, optional: true, class_name: "BxBlockCatalogue::Catalogue"
    belongs_to :account, class_name: "AccountBlock::Account"
    belongs_to :order_item, optional: true, class_name: "BxBlockOrderManagement::OrderItem"
    belongs_to :order, optional: true, class_name: "BxBlockOrderManagement::Order"

    validates_presence_of :order_id, :unless => :catalogue_id?
    validates_presence_of :catalogue_id, :unless => :order_id?
    validates :comment, :rating, presence: true

    TIME_ZONE = ENV['COUNTRY_OF_STORE'].present? ? (ENV['COUNTRY_OF_STORE'].to_s.downcase == "india" ? "Asia/Kolkata" : "Europe/London") : "Asia/Kolkata"
    # validates :account_id, :uniqueness => {:scope => [:order_item_id, :order_id]}
  end
end
