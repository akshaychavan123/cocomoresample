module Reviews
  class Load
    @@loaded_from_gem = false
    def self.is_loaded_from_gem
      @@loaded_from_gem
    end

    def self.loaded
    end

    # Check if this file is loaded from gem directory or not
    # The gem directory looks like
    # /template-app/.gems/gems/studio_store_ecommerce_[block_name]-0.0.[version]/app/admin/[admin_template].rb
    # if it has block's name in it then it's a gem
    @@loaded_from_gem = Load.method('loaded').source_location.first.include?('studio_store_ecommerce_')
  end

end

unless Reviews::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockCatalogue::Review, as: 'review' do
    menu false

    actions :all, except: [:destroy, :edit, :new ]
    permit_params :comment, :order_id, :prduct_id, :rating, :is_published

    batch_action :published do |ids|
      batch_action_collection.find(ids).each do |review|
        review.update(is_published: true)
      end
      redirect_to collection_path
    end


    batch_action :unpublished do |ids|
      batch_action_collection.find(ids).each do |review|
        review.update(is_published: false)
      end
      redirect_to collection_path, alert: "The reviews have been unpublished."
    end

    index :download_links => false do
      selectable_column
      id_column
      column :comment
      column :rating
      column "review_for", sortable: true do |review|
        if review.order.present?
          link_to review.order.order_number, edit_admin_order_path(review.order)
        elsif review.catalogue.present?
          link_to review.catalogue.name, edit_admin_product_path(review.catalogue)
        end
      end
      column :Review_date, sortable: true do |review|
        review.created_at&.in_time_zone(BxBlockCatalogue::Review::TIME_ZONE)&.strftime("%a, #{review.created_at&.in_time_zone(BxBlockCatalogue::Review::TIME_ZONE)&.day.ordinalize} %B %Y")
      end
      column 'Customer', sortable: 'accounts.name', &:account
      column :is_published
      actions defaults: true
    end

    controller do
      def scoped_collection
        BxBlockCatalogue::Review.unscoped
      end
    end
  end
end
