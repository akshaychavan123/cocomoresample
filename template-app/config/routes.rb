Rails.application.routes.draw do
  get '/filter_items/filtering/product_filter', to: 'bx_block_filter_items/filtering#product_filter'
  get '/fetch_product_variants', to: 'bx_block_catalogue/catalogues#product_variants'
  get '/fetch_products', to: 'bx_block_catalogue/catalogues#products'
  get '/fetch_products_and_variants', to: 'bx_block_catalogue/catalogues#products_and_variants'
  get '/fetch_recommended_products', to: 'bx_block_catalogue/catalogues#recommended_products'
  get '/order_management/addresses/get_address_states', to: 'bx_block_order_management/addresses#get_address_states'
  get '/onboarding/track_analytics', to: 'bx_block_onboarding_steps/onboarding#track_analytics'
  get '/onboarding/dismiss', to: 'bx_block_onboarding_steps/onboarding#dismiss'
  get "/healthcheck", to: proc { [200, {}, ["Ok"]] }
  root to: redirect('/admin')
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self) rescue ActiveAdmin::DatabaseHitDuringLoad
  get '500', to: 'application#server_error'
  get '422', to: 'application#server_error'
  get '404', to: 'application#page_not_found'
  get '/onboarding/dismiss', to: 'bx_block_admin/onboarding#dismiss'
  put '/catalogues/toggle_status', to: 'bx_block_admin/catalogues#toggle_status'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
