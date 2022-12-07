# frozen_string_literal: true
module BxBlockRoleAndPermission
  class AdminAbility
    include CanCan::Ability

    def initialize(user)
      # can :read, User
      # can :manage, User, id: user.id
      can :read, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
      # Define abilities for the passed in user here. For example:
      #
      # user ||= User.new # guest user (not logged in)
      if user.super_admin?  && BxBlockStoreProfile::BrandSetting.last.blank?
        can :manage, BxBlockApiConfiguration::QrCode
        can :manage, BxBlockRoleAndPermission::AdminProfile
        can :manage, BxBlockStoreProfile::BrandSetting
      elsif user.super_admin?
        can :manage, :all
        can :manage, BxBlockRoleAndPermission::AdminProfile
        cannot :manage, BxBlockApiConfiguration::ApiConfiguration if BxBlockStoreProfile::BrandSetting.last.blank?
        cannot [:destroy], AdminUser
        #cannot :destroy, ShippingCharge
        #cannot %i[update destroy active], OrderStatus, status: OrderStatus::CUSTOM_STATUSES
        # cannot %i[], OrderStatus, status: OrderStatus.where.not(
        #   status:OrderStatus::CUSTOM_STATUSES
        # ).pluck(:status)
        # cannot :import
      elsif user.sub_admin?
        can :manage, BxBlockRoleAndPermission::AdminProfile
        permissions = user.permissions.reject { |p| p.empty? }
        permissions.each do |p|
          next if p.to_s.downcase == "dashboard"
          #can :manage, ActsAsTaggableOn::Tag if p.to_s.downcase == 'tag'
          can :manage, p.constantize
        end
      elsif user.store_admin?
        can %i[read update], AdminUser, id: user.id
        can :read, Product
        can %i[create], Order
        can %i[read update_status cancel refund group], Order
        can [:update], Order, status: %w[placed confirmed delivered payment_failed returned]
        can [:update], Order, status: OrderStatus.new_statuses&.map(&:status)
        cannot [:update], Order, status: %w[in_transit cancelled refunded]
        cannot %i[update destroy active], OrderStatus, status: OrderStatus::CUSTOM_STATUSES
        can %i[create read update destroy active], Tracking
        can %i[create read update destroy active], OrderItem
        # can :import, Product
      end
      # else
      #     can :read, :all
      #   end
      #
      # The first argument to `can` is the action you are giving the user
      # permission to do.
      # If you pass :manage it will apply to every action. Other common actions
      # here are :read, :create, :update and :destroy.
      #
      # The second argument is the resource the user can perform the action on.
      # If you pass :all it will apply to every resource. Otherwise pass a Ruby
      # class of the resource.
      #
      # The third argument is an optional hash of conditions to further filter the
      # objects.
      # For example, here the user can only update published articles.
      #
      #   can :update, Article, :published => true
      #
      # See the wiki for details:
      # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
    end
  end
end
