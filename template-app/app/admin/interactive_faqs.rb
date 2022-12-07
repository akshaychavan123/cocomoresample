module InteractiveFaqs
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

unless InteractiveFaqs::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockInteractiveFaqs::InteractiveFaqs, as: 'Faqs' do
    menu false
    permit_params :title, :content
    # actions :all, except: [:new]

    index do
      selectable_column
      id_column
      column :title
      # column :content
      actions
    end

    show do
      attributes_table do
        row :id
        row :title
        row :content
      end
    end

    form do |f|
      render partial: "admin/email_settings/description.html.erb",locals: { title: 'Create your store - FAQs', subtitle: 'List some frequently asked questions and their answers.' }
      f.inputs do
        f.input :title, label: "Question"
        f.input :content, label: "Answer", as: :quill_editor
      end
      f.actions do
        if f.object.new_record?
          f.action :submit, label: "Create FAQ "
        else
          f.action :submit, label: "Update FAQ "
        end
        f.cancel_link(action: 'index')
      end
    end

  end
end
