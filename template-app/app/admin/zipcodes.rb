module Zipcodes
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

unless Zipcodes::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockZipcode::Zipcode, as: "Zipcode" do
    menu false
    permit_params :code, :activated, :charge, :price_less_than

    batch_action :activate do |ids|
      batch_action_collection.find(ids).each do |zipcode|
        zipcode.update(activated: true)
      end
      redirect_to collection_path
    end

    action_item :shipping_charges do
      link_to 'Shipping Charges', admin_shipping_charges_path
    end unless config.action_items.map(&:name).include?(:shipping_charges)

    batch_action :deactivate do |ids|
      batch_action_collection.find(ids).each do |zipcode|
        zipcode.update(activated: false)
      end
      redirect_to collection_path, alert: "The zipcodes have been deactivated."
    end

    action_item :download_sample_file, only: :upload_zipcode_csv do
      link_to('Download Sample File', download_admin_zipcodes_path())
    end

    collection_action :download, method: :get do
      file_name = Rails.root + "lib/zipcode.csv"
      send_file file_name, type: "application/csv"
    end

    action_item :upload_zipcode_csv, only: :index do
      link_to 'Upload CSV', :action => 'upload_zipcode_csv'
    end

    collection_action :upload_zipcode_csv do
      render "/admin/csv/upload_zipcode_csv"
    end

    form do |f|
      render partial: "admin/email_settings/description.html.erb",locals: { title: 'Set up your business - Zip codes', subtitle: "Tell us which areas you'll be shipping your products to." }
      f.inputs do
        f.input :code
        f.input :activated
        f.input :charge
        f.input :price_less_than
      end
      f.actions
    end

    collection_action :import_csv, :method => :post do
      if params[:upload_zipcode_csv] && params[:upload_zipcode_csv][:file]
        if (params[:upload_zipcode_csv][:file].content_type.include?("csv") || params[:upload_zipcode_csv][:file].content_type.include?("excel") || params[:upload_zipcode_csv][:file].content_type.include?("xls"))
          csv_errors = {}
          count, csv_errors = CsvDbZipcode.convert_save("BxBlockZipcode::Zipcode", params[:upload_zipcode_csv][:file])
          if count > 0 || csv_errors.present?
            success_message = "#{count} zipcodes uploaded/updated successfully. \n"
            error_message = ""
            if csv_errors.present?
              error_message += "CSV has error(s) on: \n"
              csv_errors.each do |error|
                error_message += error[0] + error[1].join(", ")
              end
            end
            redirect_to admin_zipcodes_path, flash: {:notice => success_message, :error => error_message}
          elsif !csv_errors.empty?
            redirect_to upload_csv_admin_zipcodes_path, flash[:error] = csv_errors
          else
            redirect_to upload_csv_admin_zipcodes_path, flash: {error: "There is some problem with CSV. Please check sample file and upload again!"}
          end
        else
          redirect_to upload_csv_admin_zipcodes_path, flash: {error: "File format not valid!"}
        end
      else
        redirect_to upload_csv_admin_zipcodes_path, flash: {error: "Please select file!"}
      end
    end
  end
end

