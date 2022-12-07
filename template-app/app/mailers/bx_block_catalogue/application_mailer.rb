module BxBlockCatalogue
  class ApplicationMailer < BuilderBase::ApplicationMailer
    default from: 'admin@store.builder.ai'
    layout 'mailer'
  end
end
