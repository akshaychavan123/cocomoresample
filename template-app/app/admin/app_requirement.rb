module AppRequirement
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

unless AppRequirement::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockApiConfiguration::AppRequirement, as: 'App Requirement' do
    menu false
    permit_params :requirement_type, :file

    actions :all, except: %i[destroy show]


    action_item :sample_app_requirement do
      link_to 'Sample app requirement', download_admin_brand_settings_path(play_store: false)
    end

    action_item :sample_play_store_requirement do
      link_to 'Sample play store requirement', download_admin_brand_settings_path(play_store: true)
    end

    form do |f|
      f.inputs do
        f.input :requirement_type, as: :select, collection: BxBlockApiConfiguration::AppRequirement.requirement_types.keys.to_a, include_blank: true, allow_blank: false, :prompt => "Select Type"
        f.input :file, :as => :file, :hint => f.object.file.present? ? '' : content_tag(:span, "")
      end
      f.actions
    end

    index :download_links => false do
      column :id
      column :requirement_type
      actions defaults: false do |r|
        link_to 'Download', rails_blob_path(r.file, disposition: 'preview'), class: 'view_link member_link'
      end
      actions
    end

    controller do
      def action_methods
        if BxBlockApiConfiguration::AppRequirement.count > 1
          super - ['new']
        else
          super
        end
      end
    end

  end
end
