module BxBlockCatalogue
  class CsvUploadLog < BxBlockCatalogue::ApplicationRecord
    self.table_name = :csv_upload_logs

    validates_presence_of :filename, :status, :job_id
    validates_uniqueness_of :job_id

    enum status: %i[in_process completed]
  end
end
