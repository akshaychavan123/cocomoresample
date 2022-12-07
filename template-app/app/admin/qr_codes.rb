module QrCodes
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

unless QrCodes::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockApiConfiguration::QrCode, as: 'QR Code' do
    menu false
    require 'rqrcode'

    actions :all

    permit_params :code_type, :url

    form do |f|
      render partial: "admin/email_settings/description.html.erb",locals: { title: 'Set up your business - QR code', subtitle: "Generate a QR code here - this lets customers download your store’s app." }
      f.inputs do
        f.input :code_type, as: :select, collection: BxBlockApiConfiguration::QrCode.code_types.keys.to_a, include_blank: true, allow_blank: false, :prompt => "Select Type"
        f.input :url
      end
      f.actions
    end

    index :download_links => false do
      column :id
      column :code_type
      column :url
      actions defaults: false do |code|
        link_to 'Download', download_qrcode_admin_qr_code_path(code, format: :png), class: 'view_link member_link'
      end
      actions defaults: false do |code|
        link_to 'View', admin_qr_code_path(code), class: 'view_link member_link'
      end
      actions defaults: false do |code|
        link_to 'Delete', admin_qr_code_path(code), method: 'delete', class: 'view_link member_link'
      end
    end

    show do
      attributes_table do
        row :code_type
        row :url
        row "QR Code" do |qr|
          qrcode = RQRCode::QRCode.new(qr.url)
          svg = qrcode.as_svg(
            color: "000",
            shape_rendering: "crispEdges",
            module_size: 4,
            standalone: true,
            use_path: true
          )
          svg.html_safe
        end
        row :created_at
        row :updated_at
      end
    end

    member_action :download_qrcode, method: :get do
      code = BxBlockApiConfiguration::QrCode.find_by(id: params[:id])
      qrcode = RQRCode::QRCode.new(code.url)
      png = qrcode.as_png(
        bit_depth: 1,
        border_modules: 4,
        color_mode: ChunkyPNG::COLOR_GRAYSCALE,
        color: 'black',
        file: nil,
        fill: 'white',
        module_px_size: 6,
        resize_exactly_to: false,
        resize_gte_to: false,
        size: 120
      )
      respond_to do |format|
        format.png { send_data png, type: 'image/png', disposition: 'attachment', :filename => "#{code.code_type}QR.png"}
      end
    end

  end
end
