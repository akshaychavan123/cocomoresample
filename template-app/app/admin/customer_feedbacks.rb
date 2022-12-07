module CustomerFeedbacks
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

unless CustomerFeedbacks::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockCatalogue::CustomerFeedback, as: 'Customer Feedback' do
    menu false
    permit_params :title, :description, :position, :customer_name, :customer_location, :is_active, :image, :catalogue_id

    index :download_links => false do
      selectable_column
      id_column
      # column :title
      column :description
      column :position
      column :customer_name
      column :is_active
      # f.input :catalogue_id, as: :select, collection: BxBlockCatalogue::Catalogue.active.map { |p| [p.name, p.id] }, :prompt => "Product", input_html: { class: 'select2' }
      column 'Image' do |customer_feedback|
        image_tag(url_for(customer_feedback.image), width: "50px", height: "50px") if customer_feedback.image.present?
      end
      # column 'Catalogue', sortable: 'catalogues.name', &:catalogue
      actions
    end

    form do |f|
      render partial: "admin/email_settings/description.html.erb",locals: { title: 'Set up your business - Customer feedback', subtitle: "Manually input customer feedback about your products, here." }
      f.inputs do
        # f.input :title
        f.input :description
        f.input :position
        f.input :customer_name
        f.input :is_active
        # f.input :catalogue_id, as: :select, collection: BxBlockCatalogue::Catalogue.all.map { |p| [p.name, p.id] }, :prompt => "Product", input_html: { class: 'select2' }
        f.input :image, :as => :file, :hint => f.object.image.present? ? image_tag(url_for(f.object.image)) : content_tag(:span, "please add image")
      end
      f.actions do
        f.action :submit
        f.cancel_link(action: 'index')
      end
    end

    show do
      attributes_table do
        # row :title
        row :description
        row :position
        row :customer_name
        row :is_active
        row 'Image' do |customer_feedback|
          image_tag(url_for(customer_feedback.image)) if customer_feedback.image.present?
        end
        row :created_at
        # row :product
      end
    end
  end
end
