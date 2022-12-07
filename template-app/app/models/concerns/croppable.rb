module Croppable
  extend ActiveSupport::Concern

  included do
    attr_reader :cropped_image
  end

  # def cropped_image=(val)
  #   return if val.blank?

  #   val= JSON.parse(val).values.last
  #   image_path='cropped_image.png'
  #   val.gsub!("data:image/png;base64,", "")
  #   File.open(image_path, 'wb') do |f|
  #     f.write(Base64.decode64(val))
  #   end
  #   self.logo.attach(io: File.open(image_path), filename: "logo.png")
  #   File.delete(image_path) if File.exist?(image_path)
  # end

  def cropped_image=(val)
    decoded_data = val.gsub!("data:image/png;base64,", "")
    image_path="tmp/cropped_image.png"
    File.open(image_path, 'wb') do |f|
      f.write(Base64.decode64(decoded_data))
    end
    self.logo.attach(io: File.open(image_path),filename: "cropped_image.png")
    File.delete(image_path) if File.exist?(image_path)
  end

end
