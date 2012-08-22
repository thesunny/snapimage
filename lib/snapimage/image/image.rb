module SnapImage
  class Image
    def self.from_path(path, public_url)
      image = SnapImage::Image.new(public_url)
      image.set_image_from_path(path)
      image
    end

    def self.from_blob(blob)
      image = SnapImage::Image.new
      image.set_image_from_blob(blob)
      image
    end

    def self.from_image(img)
      image = SnapImage::Image.new
      image.set_image_from_image(img)
      image
    end

    attr_accessor :public_url

    # Arguments:
    # * public_url:: Public URL associated with the image
    def initialize(public_url = nil)
      @public_url = public_url
    end

    # Arguments:
    # * path:: Local path or URL
    def set_image_from_path(path)
      destroy!
      @image = Magick::ImageList.new(path)
    end

    # Arguments:
    # * blob:: Image blob
    def set_image_from_blob(blob)
      destroy!
      @image = Magick::ImageList.new
      @image.from_blob(blob)
    end

    # Arguments:
    # * image:: RMagick Image
    def set_image_from_image(image)
      destroy!
      @image = image
    end

    def width
      @image.columns
    end

    def height
      @image.rows
    end

    def blob
      @image.to_blob
    end

    def destroy!
      @image.destroy! if @image && !@image.destroyed?
    end

    # Crops the image with the given parameters.
    #
    # Arguments:
    # * x:: x coordinate of the top left corner
    # * y:: y coordinate of the top left corner
    # * width:: width of the crop rectangle
    # * height:: height of the crop rectangle
    def crop(x, y, width, height)
      @image.crop!(x, y, width, height)
    end

    # Resizes the image with the given paramaters.
    #
    # Arguments:
    # * width:: Width to resize to
    # * height:: Height to resize to (optional)
    # * maintain_aspect_ratio:: If true, the image will be resized to fit within the width/height specified while maintaining the aspect ratio. If false, the image is allowed to be stretched.
    def resize(width, height = nil, maintain_aspect_ratio = true)
      raise "Height must be specified when not maintaining aspect ratio." if !maintain_aspect_ratio && !height
      # If no height is given, make sure it does not interfere with the
      # resizing.
      height ||= [width, @image.rows].max
      if maintain_aspect_ratio
        @image.resize_to_fit!(width, height)
      else
        @image.resize!(width, height)
      end
    end

    # Sharpens the image.
    def sharpen
      image = @image.sharpen
      destroy!
      @image = image
    end
  end
end
