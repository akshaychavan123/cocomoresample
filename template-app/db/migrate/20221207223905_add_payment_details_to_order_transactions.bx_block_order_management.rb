# This migration comes from bx_block_order_management (originally 20210330162197)
class AddPaymentDetailsToOrderTransactions < ActiveRecord::Migration[6.0]
  def change
    add_column :order_transactions, :status, :string, default: "pending"
    add_column :order_transactions, :razorpay_order_id, :string
    add_column :order_transactions, :payment_id, :string
    add_column :order_transactions, :razorpay_signature, :string
    add_column :order_transactions, :payment_provider, :string
  end
end
