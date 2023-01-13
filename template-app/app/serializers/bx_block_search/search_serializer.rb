module BxBlockSearch
  class SearchSerializer < BuilderBase::BaseSerializer
    attributes :name, :id, :type, :count

    attribute :category_id, if: Proc.new { |object|
      object.category_id if object.type == "catalogue"
    }

    attribute :sub_category_id, if: Proc.new { |object|
      object.sub_category_id if object.type == "catalogue"
    }
  end
end
