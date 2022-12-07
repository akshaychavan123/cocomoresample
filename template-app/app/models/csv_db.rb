require 'csv'
require 'open-uri'

class CsvDb
  class << self

    def convert_save(model_name, csv_data, csv_errors = {})
      row_count = 0
      count = 0
      @csv_errors = {}
      begin
        target_model = model_name.classify.constantize
        if target_model == BxBlockCatalogue::Catalogue
          CSV.foreach(csv_data.path, :headers => true) do |row|
            row_count += 1
            #category and sub_category create/update
            category = create_category(row['category'], row_count)
            sub_category = create_subcategory(category, row['sub_category'], row_count)
            brand = create_brand(row['brand'], row_count)
            #product create/update
            product = build_product_struct(row['sku'], sub_category, brand, row)
            product_variant = build_product_varient_struct(row, product)

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
              count+=1
            end

            if product.errors.any?
              csv_errors["Product(#{row_count}): "] = product.errors.messages.map {|key, value| key.to_s + " " + value.first.to_s}#.reject {|value| value.include?("base")}
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

    def build_product_struct(sku, sub_category, brand, row)
      product = BxBlockCatalogue::Catalogue.new do |record|
        record.sub_categories << sub_category if sub_category.present?
        record.brand_id = brand.id
        record.name = row['name']
        record.sku = row['sku']
        record.description = row['description']
        record.manufacture_date = row['manufacture_date']
        record.length = row['length']
        record.breadth = row['breadth']
        record.height = row['height']
        record.availability = row['availability']
        record.stock_qty = row['stock_qty']
        record.weight = row['weight'].present? ? row['weight'] : 1.0
        record.price = row['price']
        record.on_sale = row['on_sale']
        record.sale_price = row['sale_price']
        record.recommended = row['recommended']
        record.block_qty = row['block_qty']
        record.tax = BxBlockOrderManagement::Tax.find_or_create_by(tax_percentage: row['tax']) if row['tax'].present?
        record.sold = row['sold'].present? ? row['sold'] : 0
        record.status = 'draft'
      end
      product
    end

    def build_product_varient_struct(row, product)
      product_variant = product.catalogue_variants.new
      product_variant.catalogue_variant_properties.destroy_all if product_variant.catalogue_variant_properties.present?
      BxBlockCatalogue::Variant.all.each do |variant|
        if row["variant_" + variant.name] != nil
          variant_property = product_variant.catalogue_variant_properties.new
          variant_property.variant_property_id = BxBlockCatalogue::VariantProperty.find_by(name: row["variant_" + variant.name])&.id
          variant_property.variant_id = variant.id
        end
      end
      product_variant.price = row['variant_price']
      product_variant.stock_qty = row['variant_stock_qty']
      product_variant.on_sale = row['variant_on_sale']
      product_variant.sale_price = row['variant_sale_price']
      product_variant.discount_price = row['variant_discount_price']
      product_variant.length = row['variant_length']
      product_variant.breadth = row['variant_breadth']
      product_variant.height = row['variant_height']
      product_variant.block_qty = row['variant_block_qty']
      product_variant.tax = BxBlockOrderManagement::Tax.find_or_create_by(tax_percentage: row['variant_tax']) if row['variant_tax'].present?
      product_variant.is_default = row['default']

      if product_variant.valid?
        product_variant
      else
        product.catalogue_variants.delete_all
        nil
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

  end
end
