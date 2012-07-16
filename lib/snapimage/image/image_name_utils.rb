module SnapImage
  class ImageNameUtils
    # Base Image Format:
    # {basename}-{original dimensions}.{extname}
    #
    # Modified Image Format:
    # {basename}-{original dimensions}-{crop}-{dimensions}-{sharpen}.{extname}
    #
    # Notes
    # * crop:: {x}x{y}x{width}x{height}
    # * dimensions:: {width}x{height}
    # * sharpen:: 0 or 1
    IMAGE_PATH_REGEXP = /^(.*\/|)(([a-z0-9]{8})-(\d+)x(\d+)(-(\d+)x(\d+)x(\d+)x(\d+)-(\d+)x(\d+)-([01])|).(png|jpg|gif))$/

    class << self
      # Returns true if the path is for a base image. False otherwise.
      #
      # The path points to a base image if the dimensions are the same as the
      # original dimensions, there is no cropping, and there is no sharpening.
      def base_image?(path)
        get_image_name_parts(path)[:is_base]
      end

      # Returns the extension name of the path. Normalizes jpeg to jpg.
      def get_image_type(path)
        type =  File.extname(path).sub(/^\./, "")
        type = "jpg" if type == "jpeg"
        type
      end

      # Returns true if the name is valid. False otherwise.
      def valid?(path)
        get_image_name_parts(path)
        return true
      rescue
        return false
      end

      # Parses the following format:
      # {basename}-{original dimensions}-{crop}-{dimensions}-{sharpen}.{extname}
      # Notes about the format:
      # * crop:: {x}x{y}x{width}x{height}
      # * dimensions:: {width}x{height}
      # * sharpen:: 0 or 1
      #
      # Returns the information in a hash.
      def get_image_name_parts(path)
        matches = path.match(SnapImage::ImageNameUtils::IMAGE_PATH_REGEXP)
        raise SnapImage::InvalidImageIdentifier, "The image identifier is invalid: #{path}" unless matches
        parts = {
          is_base: matches[6].size == 0,
          full: matches[0],
          path: matches[1].sub(/\/$/, ""),
          filename: matches[2],
          basename: matches[3],
          original_dimensions: [matches[4].to_i, matches[5].to_i],
          extname: matches[14]
        }
        unless parts[:is_base]
          parts.merge!({
            crop: {
              x: matches[7].to_i,
              y: matches[8].to_i,
              width: matches[9].to_i,
              height: matches[10].to_i
            },
            dimensions: [matches[11].to_i, matches[12].to_i],
            sharpen: !!matches[13]
          })
        end
        parts
      end

      # Returns the base image name from the path.
      def get_base_image_path(path)
        parts = get_image_name_parts(path)
        "#{parts[:path]}/#{parts[:basename]}-#{parts[:original_dimensions][0]}x#{parts[:original_dimensions][1]}.#{parts[:extname]}"
      end

      # Returns the name with the new width and height.
      def get_resized_image_name(name, width, height)
        parts = SnapImage::ImageNameUtils.get_image_name_parts(name)
        if parts[:is_base]
          resized_name = SnapImage::ImageNameUtils.generate_image_name(width, height, parts[:extname], basename: parts[:basename])
        else
          options = {
            basename: parts[:basename],
            crop: parts[:crop],
            width: width,
            height: height,
            sharpen: parts[:sharpend]
          }
          resized_name = SnapImage::ImageNameUtils.generate_image_name(parts[:original_dimensions][0], parts[:original_dimensions][1], parts[:extname], options)
        end
        resized_name
      end

      # Generates a random alphanumeric string of 8 characters.
      def generate_basename
        (0...8).map { rand(36).to_s(36) }.join
      end

      # When no options besides :basename are given, generates a base image
      # name in the format:
      # {basename}-{original dimensions}.{extname}
      #
      # Otherwise, generates a modified image name in the format:
      # {basename}-{original dimensions}-{crop}-{dimensions}-{sharpen}.{extname}
      #
      # Notes about the format:
      # * crop:: {x}x{y}x{width}x{height}
      # * dimensions:: {width}x{height}
      # * sharpen:: 0 or 1
      #
      # Options:
      # * basename:: Defaults to a randomly generated basename of 8 characters
      # * crop:: Crop values {x: <int>, y: <int>, width: <int>, height: <int>}
      # * width:: New width
      # * height:: New height
      # * sharpen:: True or false
      def generate_image_name(original_width, original_height, extname, options = {})
        basename = options.delete(:basename) || self.generate_basename
        if options.empty?
          "#{basename}-#{original_width}x#{original_height}.#{extname}"
        else
        "#{basename}-#{original_width}x#{original_height}-#{options[:crop][:x]}x#{options[:crop][:y]}x#{options[:crop][:width]}x#{options[:crop][:height]}-#{options[:width]}x#{options[:height]}-#{options[:sharpen] ? 1 : 0}.#{extname}"
        end
      end
    end
  end
end
