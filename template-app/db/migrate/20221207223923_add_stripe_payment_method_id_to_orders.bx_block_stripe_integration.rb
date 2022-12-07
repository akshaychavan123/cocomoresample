# This migration comes from bx_block_stripe_integration (originally 20210420145015)
class AddStripePaymentMethodIdToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :stripe_payment_method_id, :string
  end
end
