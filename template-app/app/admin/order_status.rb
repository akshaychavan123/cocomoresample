# frozen_string_literal: true

module OrderStatus
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

unless OrderStatus::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockOrderManagement::OrderStatus, as: "OrderStatus" do
    menu false

    permit_params :status, :active, :message, :name
    actions :all, except: [:show, :new]

    member_action :active, method: :put do
      unless resource.active
        resource.update(active:true)
      else
        resource.update(active:false)
      end
      redirect_to request.referer
    end


    filter :name
    filter :message

    index :download_links => false do
      column :name
      column :message
      actions defaults: false do |object|
        unless BxBlockOrderManagement::OrderStatus::CUSTOM_STATUSES.include?(object.status)
          links = []
          links << link_to('Edit', edit_admin_order_status_path(object), :class => "member_link edit_link")
          links << link_to('Delete', admin_order_status_path(object), method: :delete, confirm: 'Are you sure?', class: "member_link delete_link")
          links.join(' ').html_safe
        end
      end
    end

    form do |f|
      f.inputs 'Order Status' do
        f.input :name
        f.input :message
        actions
      end
    end


    show do
      attributes_table do
        row :name
        row :message
      end
    end
  end
end
