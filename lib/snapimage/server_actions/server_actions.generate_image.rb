module SnapImage
  module ServerActions
    class GenerateImage
      include SnapImage::ServerActions::Authorize

      def initialize(config, request, response)
        @config = config
        @storage = config.storage
        @request = request
        @response = response
      end

      def call
        authorize(:client)
        if request_valid?
          image = get_image_for_modification
          parts = SnapImage::ImageNameUtils.get_image_name_parts(image.public_url)
          result = modify_image(image)
          modified_image = result[:image]
          modified_image_name = result[:name]
          stored_image = @storage.add_image(modified_image, modified_image_name, @request.json["resource_identifier"])
          @response.set_success(
            message: "Get Modified Image Successful",
            image_url: stored_image.public_url,
            image_width: stored_image.width,
            image_height: stored_image.height
          )
        else
          @response.set_bad_request
        end
        @response
      end

      private

      # Returns true if the request is valid. False otherwise.
      def request_valid?
        source_image_defined?
      end

      # Returns true if either "file" or JSON "url" is defined.
      def source_image_defined?
        !!(@request.file || @request.json["url"])
      end

      # Returns true if the image is being uploaded. False otherwise.
      def upload?
        @request.file || !@storage.local?(@request.json["url"])
      end

      # Returns true if cropping is required. False otherwise.
      def crop?
        @request.json["crop_x"] || @request.json["crop_y"] || @request.json["crop_width"] || @request.json["crop_height"]
      end

      # Returns true if all the cropping values are defined. False otherwise.
      def crop_valid?
        @request.json["crop_x"] && @request.json["crop_y"] && @request.json["crop_width"] && @request.json["crop_height"]
      end

      # Returns true if resizing is required. False otherwise.
      def resize?
        @request.json["width"] || @request.json["height"]
      end

      # Returns true if the image is too large and needs to be resized to fit.
      # False otherwise.
      def resize_to_fit?(image)
        image.width > get_max_width || image.height > get_max_height
      end

      # Returns true if sharpening is required. False otherwise
      def sharpen?
        @request.json["sharpen"]
      end

      # Gets the max width. Takes the lesser of the JSON "max_width" or the
      # server max width.
      def get_max_width
        server_max_width = @config["max_width"]
        [(@request.json["max_width"] && @request.json["max_width"].to_i || server_max_width), server_max_width].min
      end

      # Gets the max height. Takes the lesser of the JSON "max_height" or the
      # server max height.
      def get_max_height
        server_max_height = @config["max_height"]
        [(@request.json["max_height"] && @request.json["max_height"].to_i || server_max_height), server_max_height].min
      end

      def get_image_for_modification
        if upload?
          # Add the image to the storage.
          if @request.file
            image = @storage.add_upload(@request.file, @request.json["resource_identifier"])
          else
            image = @storage.add_url(@request.json["url"], @request.json["resource_identifier"])
          end
        else
          # Get the base image.
          raise SnapImage::InvalidImageIdentifier unless SnapImage::ImageNameUtils.valid?(@request.json["url"])
          image = @storage.get(SnapImage::ImageNameUtils.get_base_image_path(@request.json["url"]))
        end
        image
      end

      # Arguments:
      # * image:: SnapImage::Image object that represents the base image
      def modify_image(image)
        parts = SnapImage::ImageNameUtils.get_image_name_parts(image.public_url)

        # Crop.
        cropped = crop?
        crop = nil
        if cropped
          raise SnapImage::BadRequest, "Missing crop values." unless crop_valid?
          crop = {
            x: @request.json["crop_x"],
            y: @request.json["crop_y"],
            width: @request.json["crop_width"],
            height: @request.json["crop_height"]
          }
          image = image.crop(crop[:x], crop[:y], crop[:width], crop[:height])
        end

        # Resize.
        resized = resize?
        if resized
          width = @request.json["width"] && @request.json["width"].to_i
          height = @request.json["height"] && @request.json["height"].to_i
          if width && height
            # When both width and height are specified, resize without
            # maintaining the aspect ratio.
            image = image.resize(width, height, false)
          else
            # When only one of width/height is specified, set the other to the
            # max and maintain the aspect ratio.
            image = image.resize(width || @config["max_width"], height || @config["max_height"])
          end
        end

        # Resize to fit.
        resized_to_fit = resize_to_fit?(image)
        image = image.resize(get_max_width, get_max_height) if resized_to_fit

        # Sharpen.
        sharpened = sharpen?
        image = image.sharpen if sharpened

        # Get the dimensions at the end.
        if cropped || resized || resized_to_fit || sharpened
          modifications = {
            crop: crop || { x: 0, y: 0, width: parts[:original_dimensions][0], height: parts[:original_dimensions][1] },
            width: image.width,
            height: image.height,
            sharpen: sharpened
          }
          name = SnapImage::ImageNameUtils.generate_image_name(parts[:original_dimensions][0], parts[:original_dimensions][1], parts[:extname], {basename: parts[:basename]}.merge(modifications))
        else
          name = parts[:filename]
        end

        { image: image, name: name }
      end
    end
  end
end
