# This migration comes from bx_block_catalogue (originally 20230105112849)
class CreateCsvUploadLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :csv_upload_logs do |t|
      t.string :filename
      t.integer :status
      t.string :job_id
      t.text :error_message
      t.string :success_message

      t.timestamps
    end
  end
end
