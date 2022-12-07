module AccountBlock
  class UpdateUserData
    ASSOCIATED_DATA = %w[wishlist orders delivery_addresses].freeze
    attr_accessor :params, :current_resource_owner, :user

    def initialize(params = {}, current_resource_owner)
      @params = params
      @current_resource_owner = current_resource_owner
      @user = AccountBlock::Account.where(uuid: params[:uuid], guest: true).order(created_at: :desc).first if params[:uuid].present?
    end

    def call
      if user
        manage_data
        destroy_delivery_addresses
        destroy_guest_user
        destroy_other_guest_users
      end
    end

    def manage_data
      ASSOCIATED_DATA.each do |amd|
        define_singleton_method("add_#{amd}") do
          case amd
          when 'wishlist'
            manage_wishlists
          when 'orders'
            manage_order_items
          else
            current_user(amd) << guest_user(amd) if guest_user(amd).present?
          end
        end
        send("add_#{amd}")
      end
    end

    def current_user(amd)
      current_resource_owner.send(amd)
    end

    def guest_user(amd)
      user.send(amd)
    end

    def destroy_guest_user
      user&.destroy
    end

    def destroy_other_guest_users
      other_users = AccountBlock::Account.where(uuid: params[:uuid], guest: true)
      if other_users.present? && other_users.count > 0
        other_users.destroy_all
      end
    end

    def destroy_delivery_addresses
      if user.delivery_addresses.present?
        user.delivery_addresses.each do |da|
          da.destroy!
        end
      end
    end

    def manage_order_items
      order = current_resource_owner.orders.find_by(status: 'in_cart')
      guest_user_order = user.orders.where(status: 'in_cart').first
      if guest_user_order.present?
        if order.present?
          remaining_items = guest_user_order.order_items.where(catalogue_id: (guest_user_order.order_items.pluck(:catalogue_id) - order.order_items.pluck(:catalogue_id)))
          order.order_items << remaining_items
          BxBlockOrderManagement::UpdateCartValue.new(order, current_resource_owner).call
        else
          current_resource_owner.orders << guest_user_order
        end
      end
    end

    def manage_wishlists
      current_user_wishlists = current_resource_owner.wishlist.wishlist_items if current_resource_owner.wishlist.present?
      guest_user_wishlists = user.wishlist.wishlist_items if user.wishlist.present?

      if current_user_wishlists.present? && guest_user_wishlists.present?
        catalogue_ids = guest_user_wishlists.pluck(:catalogue_id) - current_user_wishlists.pluck(:catalogue_id)
      elsif !current_user_wishlists.present? && guest_user_wishlists.present?
        catalogue_ids = guest_user_wishlists.pluck(:catalogue_id)
      end
      if catalogue_ids.present?
        @catalogues = BxBlockCatalogue::Catalogue.active.where(id: catalogue_ids)
        @catalogues.each do |catalogue|
          BxBlockWishlist::CreateWishList.new(catalogue, nil, current_resource_owner).call
        end
      end
    end
  end
end
