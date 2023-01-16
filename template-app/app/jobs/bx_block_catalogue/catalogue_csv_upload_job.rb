module BxBlockCatalogue
  class CatalogueCsvUploadJob < ApplicationJob
    queue_as :default

    def perform(file_path)
      filename = file_path&.split('/')[1]
      set_csv_log(job_id, 'in_process', filename)

      file = File.read(Rails.root.join(file_path))
      save_catalogue(file)

      success_message = "#{@count} products uploaded/updated successfully. \n"
      error_message = nil
      if @csv_errors.present?
        error_message = "CSV has error(s) on: \n"
        @csv_errors.each do |error|
          error_message += error[0] + error[1].join(", ")
        end
      end

      set_csv_log(job_id, 'completed', filename, success_message, error_message)
      File.delete(file_path) if File.exist?(file_path)

      return { message: success_message, errors: error_message }
    end

    def save_catalogue(file)
      row_count = 0
      @count = 0
      @csv_errors = {}
      begin
        csv = CSV.parse(file, :headers => true)
        csv.each do |row|
          row_count += 1
          #category and sub_category create/update
          category = create_category(row['category'], row_count)
          sub_category = create_subcategory(category, row['sub_category'], row_count)
          brand = create_brand(row['brand'], row_count)
          variant_properties = create_variants(row, row_count)
          #product create/update
          product = build_product_struct(row['sku'], sub_category, brand, row)
          product_variant = new_product_variant_struct(row, product, variant_properties)

          if product.save
            row['tags']&.split(',')&.each do |tag|
              tag = BxBlockCatalogue::Tag.find_or_create_by(name: "#{tag.lstrip}")
              product.tags.find_by(id: tag.id).present? ? product.tags : product.tags << tag
            end
            if product_variant.present?
              product_variant.save
              if product_variant.errors.any?
                csv_errors["Product Variant(#{row_count}): "] = product_variant.errors.messages.map {|key, value| key.to_s + " " + value.first.to_s}
              end
            end
            @count+=1
          end

          if product.errors.any?
            csv_errors["Product(#{row_count}): "] = product.errors.messages.map {|key, value| key.to_s + " " + value.first.to_s}#.reject {|value| value.include?("base")}
          end
        end
      rescue Exception => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join("\n")
      end
    end

    def create_category(cat_name, row_count)
      category = BxBlockCategoriesSubCategories::Category.find_or_initialize_by(name: cat_name)
      category.from_csv = true
      category.save
      if category.errors.any?
        @csv_errors["row(#{row_count}): category "] = category.errors.values
      end
      category
    end

    def create_subcategory(category, sub_cat_name, row_count)
      return nil if sub_cat_name.blank?
      sub_category = category.sub_categories.find_or_initialize_by(name: sub_cat_name)
      sub_category.from_csv = true
      sub_category.save
      if sub_category.errors.any?
        @csv_errors["row(#{row_count}): sub category "] = sub_category.errors.values
      end
      sub_category
    end

    def create_brand(brand_name, row_count)
      brand = BxBlockCatalogue::Brand.find_or_create_by(name: brand_name)
      if brand.errors.any?
        @csv_errors["row(#{row_count}): brand "] = brand.errors.values
      end
      brand
    end

    def create_variants(row, row_count)
      variant_properties = []
      count = 1
      while true
        variant_name = row["variant_#{count}_name"]
        variant_property = row["variant_#{count}_options"]
        break if variant_name.blank? || variant_property.blank?

        variant = BxBlockCatalogue::Variant.find_or_initialize_by(name: variant_name)
        new_variant_property = variant.variant_properties.find_or_initialize_by(name: variant_property)
        variant.new_record? ? variant.save : (new_variant_property.new_record? && new_variant_property.save)

        if variant.errors.any?
          @csv_errors["row(#{row_count}): variant "] = variant.errors.values
        elsif new_variant_property.errors.any?
          @csv_errors["row(#{row_count}): variant property "] = new_variant_property.errors.values
        else
          variant_properties << new_variant_property
        end

        count += 1
      end
      variant_properties
    end

    def build_product_struct(sku, sub_category, brand, row)
      product = BxBlockCatalogue::Catalogue.find_or_initialize_by(sku: sku)
      product.sub_categories << sub_category if sub_category.present? && !product.sub_categories.include?(sub_category)
      product.brand = brand if brand.present?
      product.name = row['name'] if row['name'].present?
      product.description = row['description'] if row['description'].present?
      product.manufacture_date = row['manufacture_date'] if row['manufacture_date'].present?
      product.length = row['length'] if row['length'].present?
      product.breadth = row['breadth'] if row['breadth'].present?
      product.height = row['height'] if row['height'].present?
      product.availability = row['availability'] if row['availability'].present?
      product.stock_qty = row['stock_qty'] if row['stock_qty'].present?
      product.weight = row['weight'].present? ? row['weight'] : 1.0
      product.price = row['price'] if row['price'].present?
      product.on_sale = row['on_sale'] if row['on_sale'].present?
      product.sale_price = row['sale_price'] if row['sale_price'].present?
      product.recommended = row['recommended'] if row['recommended'].present?
      product.discount = row['discount'] if row['discount'].present?
      product.block_qty = row['block_qty'] if row['block_qty'].present?
      product.tax = BxBlockOrderManagement::Tax.find_or_create_by(tax_percentage: row['tax']) if row['tax'].present?
      product.sold = row['sold'].present? ? row['sold'] : 0
      product.status = 'draft'
      product = attach_image_from_url(product, row['product_image']) if row['product_image'].present?
      product
    end

    def new_product_variant_struct(row, product, variant_properties)
      product_variant = product.catalogue_variants.select { |cv| cv.catalogue_variant_properties.pluck(:variant_property_id).sort == variant_properties.pluck(:id).sort }.first
      if product_variant.nil?
        product_variant = product.catalogue_variants.new
        variant_properties.each do |variant_property|
          product_variant.catalogue_variant_properties.new(variant_property: variant_property)
        end
      end
      product_variant.price = row['variant_price'] if row['variant_price'].present?
      product_variant.stock_qty = row['variant_stock_qty'] if row['variant_stock_qty'].present?
      product_variant.on_sale = row['variant_on_sale'] if row['variant_on_sale'].present?
      product_variant.sale_price = row['variant_sale_price'] if row['variant_sale_price'].present?
      product_variant.discount_price = row['variant_discount_price'] if row['variant_discount_price'].present?
      product_variant.length = row['variant_length'] if row['variant_length'].present?
      product_variant.breadth = row['variant_breadth'] if row['variant_breadth'].present?
      product_variant.height = row['variant_height'] if row['variant_height'].present?
      product_variant.block_qty = row['variant_block_qty'] if row['variant_block_qty'].present?
      product_variant.tax = BxBlockOrderManagement::Tax.find_or_create_by(tax_percentage: row['variant_tax']) if row['variant_tax'].present?
      product_variant.is_default = row['default'] if row['default'].present?
      product_variant = attach_image_from_url(product_variant, row['variant image']) if row['variant image'].present?

      if product_variant.valid?
        product_variant
      else
        product.catalogue_variants.delete_all
        nil
      end
    end

    def attach_image_from_url(object, image_url)
      begin
        image_url = image_url.strip
        url = URI.parse(image_url)
        filename = File.basename(url.path)
        file = URI.open(url)
        attachment = object.attachments.new
        attachment.image.attach(io: file, filename: filename)
      rescue
        return object
      end
      object
    end

    def set_csv_log(job_id, status, filename, success_message = nil, error_message = nil)
      csv_log = CsvUploadLog.find_or_initialize_by(job_id: job_id)
      csv_log.assign_attributes(status: status, filename: filename, success_message: success_message, error_message: error_message)
      csv_log.save
    end
  end
end
