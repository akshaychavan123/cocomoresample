# This migration comes from bx_block_order_management (originally 20210531102604)
class AddStripePaymentIdToOrderTransaction < ActiveRecord::Migration[6.0]
  def change
    add_column :order_transactions, :stripe_payment_id, :string
  end
end
