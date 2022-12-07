# This migration comes from bx_block_search (originally 20210317091044)
class AddColumnsToRecentSearch < ActiveRecord::Migration[6.0]
  def change
    add_column :recent_searches, :search_id, :integer
    add_column :recent_searches, :search_type, :string
    add_column :recent_searches, :result_count, :integer
    add_column :recent_searches, :user_id, :integer
  end
end
