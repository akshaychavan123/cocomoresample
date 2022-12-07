require 'csv'
require 'open-uri'

class CsvDbCategory
  class << self

    def convert_save(model_name, csv_data, csv_errors = {})
      row_count = 0
      count = 0
      @csv_errors = {}
      begin
        target_model = model_name.classify.constantize
        if target_model == BxBlockCategoriesSubCategories::Category
          CSV.foreach(csv_data.path, :headers => true) do |row|
            row_count += 1
            #category and sub_category create/update
            category = create_category(row['category_name'], row_count)
            category = attach_category_attachments(category, row['category_image_url'])

            unless row['sub_category_name'].blank?
              sub_category = create_subcategory(category, row['sub_category_name'], row_count)
              sub_category = attach_sub_category_attachments(sub_category, row['sub_category_image_url'])
            end

            if category.save
              count+=1
            end

            if category.errors.any?
              csv_errors["Category(#{row_count}): "] = category.errors.messages.map {|key, value| key.to_s + " " + value.first.to_s}#.reject {|value| value.include?("base")}
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

    def attach_sub_category_attachments(sub_category, sub_category_image)
      sub_category_image_arr = []
      file_url = URI.parse(sub_category_image.lstrip) rescue nil
      if file_url
        file = open(sub_category_image.strip) rescue nil
        sub_category_image_arr << {io: file,filename: "#{sub_category&.name&.split&.first}.#{file.content_type_parse.first.split("/").last}",content_type: file.content_type_parse.first}
      end
      if sub_category_image_arr&.any?
        sub_category_image_arr.each do |img|
          sub_category.from_csv = true
          sub_category.image.attach(img)
        end
      end
      sub_category
    end

    def attach_category_attachments(category, category_image)
      category_image_arr = []
      file_url = URI.parse(category_image.lstrip) rescue nil
      if file_url
        file = open(category_image.strip) rescue nil
        category_image_arr << {io: file,filename: "#{category&.name&.split&.first}.#{file.content_type_parse.first.split("/").last}",content_type: file.content_type_parse.first}
      end
      if category_image_arr&.any?
        category_image_arr.each do |cat_img|
          category.from_csv = true
          category.image.attach(cat_img)
        end
      end
      category
    end

    def create_category(cat_name, row_count)
      category = BxBlockCategoriesSubCategories::Category.find_or_initialize_by(name: cat_name)
      category.from_csv = true
      if category.errors.any?
        @csv_errors["row(#{row_count}): category "] = category.errors.values
      end
      category
    end

    def create_subcategory(category, sub_cat_name, row_count)
      sub_category = category.sub_categories.new(name: sub_cat_name)
      sub_category.from_csv = true
      if sub_category.errors.any?
        @csv_errors["row(#{row_count}): sub category "] = sub_category.errors.values
      end
      sub_category
    end
  end
end
