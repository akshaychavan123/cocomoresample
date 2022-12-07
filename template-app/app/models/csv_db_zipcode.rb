require 'csv'
require 'open-uri'

class CsvDbZipcode
  class << self

    def convert_save(model_name, csv_data, csv_errors = {})
      row_count = 0
      count = 0
      @csv_errors = {}
      begin
        target_model = model_name.classify.constantize
        if target_model == BxBlockZipcode::Zipcode
          CSV.foreach(csv_data.path, :headers => true) do |row|
            row_count += 1
            zipcode = BxBlockZipcode::Zipcode.find_or_create_by(code: row['zip_code'])
            zipcode.activated = row['activated']
            zipcode.charge = row['charge']
            zipcode.price_less_than = row['price_less_than']
            if zipcode.save
              count+=1
            end

            if zipcode.errors.any?
              csv_errors["Zipcode(#{row_count}): "] = zipcode.errors.messages.map {|key, value| key.to_s + " " + value.first.to_s}
            end
          end
          count
        else
          CSV.foreach(csv_data.path, :headers => true) do |row|
            target_model.create(row.to_hash)
          end
        end
      rescue Exception => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join("\n")
      end
      [count, csv_errors]
    end
  end
end
