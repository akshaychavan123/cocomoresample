module Coupons
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

unless Coupons::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockCouponCodeGenerator::CouponCode, as: "Coupon" do
    menu priority: 5, :label => "<i class='fa fa-gift gray-icon'></i> Promotions".html_safe

    permit_params :title,
                  :description,
                  :code,
                  :discount_type,
                  :discount,
                  :valid_from,
                  :valid_to,
                  :min_cart_value,
                  :max_cart_value

    form do |f|
      render partial: "admin/email_settings/description.html.erb",locals: { title: 'Set up your business - Coupons', subtitle: "Generate a coupon code here - this lets customers apply coupon on cart value." }
      f.semantic_errors
      f.inputs do
        f.input :title
        f.input :description
        f.input :code
        f.input :discount_type, as: :select, collection: BxBlockCouponCodeGenerator::CouponCode::DISCOUNT_TYPE.keys.map { |u| [u.to_s.titleize, u] }, include_blank: false
        f.input :discount
        f.input :valid_from, as: :datepicker
        f.input :valid_to, as: :datepicker
        f.input :min_cart_value
        f.input :max_cart_value
      end
      f.actions
    end

  end
end