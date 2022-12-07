module BulkUpload
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

unless BulkUpload::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockCatalogue::BulkImage, as: "Bulk Upload" do
    menu false
    permit_params :images, :image

    controller do
      def create
        if (params[:bulk_image].nil?)
          flash[:error] = "Please choose images"
          redirect_to new_admin_bulk_upload_path
        else
          BxBlockCatalogue::BulkImage.transaction do
            all_images = strong_params[:bulk_image][:images]
            all_images.each do |image|
              BxBlockCatalogue::BulkImage.new(image: image).save!
            end
            redirect_to admin_bulk_uploads_path
          rescue StandardError => e
            flash[:error] = e.message
            redirect_to new_admin_bulk_upload_path
            raise ActiveRecord::Rollback
          end
        end
      end


      def strong_params
        params.permit(bulk_image: [images: []])
      end

      def get_images
        if params[:catalogue_id].present?
          BxBlockCatalogue::BulkImage.joins(:catalogues).where(catalogues_bulk_images: {catalogue_id: params[:catalogue_id]})
        else
          BxBlockCatalogue::BulkImage.all
        end
      end

      def create_urls_for (images)
        images.collect do |object|
          object.image.attached? ? url_for(object.image) : nil
        end.compact
      end

      def filter_image_by_name (images, name)
        images.joins("INNER JOIN active_storage_attachments ON bulk_images.id = active_storage_attachments.record_id AND active_storage_attachments.record_type = 'BxBlockCatalogue::BulkImage' INNER JOIN active_storage_blobs on active_storage_blobs.id = active_storage_attachments.blob_id AND active_storage_blobs.filename ILIKE '%#{name}%'")
      end
    end

    collection_action :list_of_images do
      images = get_images
      images = filter_image_by_name(images, params[:name]) if params[:name].present?
      images = images.page(params[:page]).per(18).order(created_at: "desc")
      if params[:page].nil?
        images = images.page(1).per(18)
      end
      render json: {success: true, image_urls: create_urls_for(images)}.to_json
    end

    form do |f|
      f.inputs 'Bulk Images' do
        f.input :images, as: :file, input_html: { multiple: true ,class: 'bulk-upload-multiple-file'}
      end
      f.actions do
        # f.action :submit,
        #   button_html: {
        #     label: 'Custom label',
        #     class: "btn primary",
        #     data: {disable_with:  'Uploading...'}
        # }
        render partial: "admin/email_settings/msg.html.erb" end
    end
    # render partial: "admin/email_settings/msg.html.erb" end

    index do
      selectable_column
      id_column
      column :image do |bulk_image|
        div :class => "cat_img" do
          image_tag(url_for(bulk_image.image)) if bulk_image.image.present?
        end
      end
    end
  end
end
