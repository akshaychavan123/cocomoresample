# == Schema Information
#
# Table name: interactive_faqs
#
#  id         :bigint           not null, primary key
#  title      :string
#  content    :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
module BxBlockInteractiveFaqs
  class InteractiveFaqs < BxBlockInteractiveFaqs::ApplicationRecord
    self.table_name = :interactive_faqs

    SERIALIZE_ATTRIBUTES = %w[id title content created_at updated_at].freeze

    validates :title, presence: true, uniqueness: true
    validates :content, presence: true

    before_save :set_content
    after_create :track_event

    def track_event
      Analytics.track(user_id: ENV["HOST_URL"].split("-")[1],event: 'New faqs Created')
    end

    def to_custom_hash
      result = {}

      SERIALIZE_ATTRIBUTES.each do |cur_attr|
        result[cur_attr] = send(cur_attr)
      end

      result
    end

    def set_content
      self.content = self.content.gsub("\"", "'")
    end
  end
end
