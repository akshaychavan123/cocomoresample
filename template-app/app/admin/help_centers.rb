module HelpCenters
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

unless HelpCenters::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockHelpCenter::HelpCenter, as: 'Help Centers' do
    menu priority: 6, :label => "<i class='fa fa-pager gray-icon'></i> Static Pages".html_safe

    permit_params :help_center_type, :title, :description

    index do
      selectable_column
      id_column
      column :help_center_type do |object|
        object&.help_center_type.to_s.titleize
      end
      column :title
      column :description do |object|
        object&.description&.html_safe
      end

      actions defaults: false do |object|
        links = []
        if object&.help_center_type.to_s.titleize == "Terms Of Service" || object&.help_center_type.to_s.titleize == "Privacy Policy"
          links << link_to('View', admin_help_center_path(object), :class => "member_link view_link")
          links << link_to('Edit', edit_admin_help_center_path(object), :class => "member_link edit_link")
        else
          links << link_to('View', admin_help_center_path(object), :class => "member_link view_link")
          links << link_to('Edit', edit_admin_help_center_path(object), :class => "member_link edit_link")
          links << link_to('Delete', admin_help_center_path(object), method: :delete, class: "member_link delete_link", data: {confirm: 'Are you Sure?'})
        end
        links.join(' ').html_safe
      end
    end

    show do
      attributes_table do
        row :id
        row :help_center_type
        row :title
        row :description do |object|
          object&.description&.html_safe
        end
      end
    end

    form do |f|
      f.inputs do
        f.input :help_center_type, as: :select, input_html: f.object.new_record? ? {} : ((f.object[:help_center_type].to_s.titleize == "Privacy Policy" || f.object[:help_center_type].to_s.titleize == "Terms Of Service") ? { readonly: true, disabled: true, class: 'select2' } : {class: 'select2'} )
        f.input :title
        f.input :description, as: :quill_editor
      end
      f.actions
    end

  end
end
