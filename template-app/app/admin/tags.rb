module Tags
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

unless Tags::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockCatalogue::Tag, as: "Tags" do
    menu false
    actions :all, :except => [:show]

    permit_params :name

    form do |f|
      render partial: "admin/email_settings/description.html.erb",locals: { title: 'Add your products - Tags', subtitle: 'Create a list of labels that apply to your products - so customers can filter them more easily.' }
      f.inputs 'Tags' do
        f.input :name
      end
      f.actions
    end

    filter :name

  end
end