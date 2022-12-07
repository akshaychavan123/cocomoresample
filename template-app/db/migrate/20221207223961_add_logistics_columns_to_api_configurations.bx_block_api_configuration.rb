# This migration comes from bx_block_api_configuration (originally 20210331091649)
class AddLogisticsColumnsToApiConfigurations < ActiveRecord::Migration[6.0]
  def change
    add_column :api_configurations, :oauth_site_url, :string
    add_column :api_configurations, :base_url, :string
    add_column :api_configurations, :client_id, :string
    add_column :api_configurations, :client_secret, :string
    add_column :api_configurations, :logistic_api_key, :string
  end
end
