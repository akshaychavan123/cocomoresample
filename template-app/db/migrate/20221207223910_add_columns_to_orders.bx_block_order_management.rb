# This migration comes from bx_block_order_management (originally 20210419085357)
class AddColumnsToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :ship_rocket_order_id, :string
    add_column :orders, :ship_rocket_shipment_id, :string
    add_column :orders, :ship_rocket_status, :string
    add_column :orders, :ship_rocket_status_code, :string
    add_column :orders, :ship_rocket_onboarding_completed_now, :string
    add_column :orders, :ship_rocket_awb_code, :string
    add_column :orders, :ship_rocket_courier_company_id, :string
    add_column :orders, :ship_rocket_courier_name, :string
    add_column :orders, :logistics_ship_rocket_enabled, :boolean, default: false
    add_column :orders, :availability_checked_at, :datetime
    add_column :orders, :is_blocked, :boolean
  end
end
