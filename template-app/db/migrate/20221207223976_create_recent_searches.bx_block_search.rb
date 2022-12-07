# This migration comes from bx_block_search (originally 20210316191113)
class CreateRecentSearches < ActiveRecord::Migration[6.0]
  def change
    create_table :recent_searches do |t|
      t.string :search_term

      t.timestamps
    end
  end
end
