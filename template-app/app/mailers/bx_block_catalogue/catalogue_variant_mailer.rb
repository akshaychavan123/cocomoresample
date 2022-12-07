module BxBlockCatalogue
  class CatalogueVariantMailer < BxBlockCatalogue::ApplicationMailer
    include Devise::Mailers::Helpers
    default from: 'admin@store.builder.ai'
    layout 'mailer'

    def product_stock_notification(product, user)
      @variant = product if product.class.name == "BxBlockCatalogue::CatalogueVariant"
      @product =  product.class.name == "BxBlockCatalogue::CatalogueVariant" ? product.catalogue : product
      @user = user
      subject = product.class.name == "BxBlockCatalogue::CatalogueVariant" ? "Product Variant is Back" : "Product is Back"
      @content = BxBlockSettings::EmailSetting.where(event_name: 'product stock notification')&.first&.content
      mail(to: @user.email.downcase, subject: subject) if @user.email.present?
    end

    def product_low_stock_notification(product, admin_user)
      if product.class.name == "BxBlockCatalogue::CatalogueVariant"
        @variant = product
        @product = product.catalogue
      else
        @product = product
      end
      subject = "Low Inventory alert!"
      @admin_user = admin_user
      @content = BxBlockSettings::EmailSetting.find_by(event_name: 'product low stock notification')&.content
      mail(to: @admin_user.email.downcase, subject: subject) if @admin_user.email.present?
    end
  end
end
