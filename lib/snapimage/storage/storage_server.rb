module SnapImage
  module StorageServer
    class Base
      # Config:
      # * name:: Name of the storage.
      # * public_url:: URL to acces the storage.
      def initialize(config)
        @config = config
        validate_config
      end

      def name
        @config["name"]
      end

      # Returns a regular expression for matching urls handled by this storage
      # server.
      def url_regexp
        @url_regexp ||= /#{@config["public_url"]}\/.+?\.(png|gif|jpg)/
      end

      def local?(url)
        !!url.match(url_regexp)
      end

      # Stores the file in the storage and returns a SnapImage::Image object.
      # Arguments:
      # * file:: File object representing the file to store.
      # * type:: File type
      # * resource_id:: Resource identifier.
      def store_file(file, type, resource_id)
        raise "#store_file needs to be overridden."
      end

      # Downloads the file and adds it to the storage and returns a
      # SnapImage::Image object.
      # Arguments:
      # * url:: Url to get the image
      # * type:: File type
      # * resource_id:: Resource identifier.
      def store_url(url, type, resource_id)
        raise "#store_url needs to be overridden."
      end

      # Adds the image to the storage. Overwrites existing file.
      # Arguments:
      # * image:: SnapImage::Image object
      # * name:: Name of the image
      # * resource_id:: Resource identifier
      def store_image(image, name, resource_id)
        raise "#store_image needs to be overridden."
      end

      # Returns the SnapImage:Image object from the url.
      def get(url)
        raise "#get needs to be overriden."
      end

      # Returns all the image urls for the given resource in the storage.
      # Arguments:
      # * resource_id:: Filter by resource identifier
      # * timestamp:: Only images that were updated before the DateTime
      def get_resource_urls(resource_id, timestamp = nil)
        raise "#get_all_urls needs to be overriden."
      end

      # Deletes the given url.
      def delete(url)
        raise "#delete needs to be overridden."
      end

      # Deletes the given resource images.
      def delete_resource_images(resource_id)
        raise "#delete_resource needs to be overridden."
      end

      private

      # Validates the config. Subclasses should add to this.
      def validate_config
        raise InvalidStorageConfig, 'Missing "name"' unless @config["name"]
        raise InvalidStorageConfig, 'Missing "public_url"' unless @config["public_url"]
        raise InvalidStorageConfig, 'Missing "max_width"' unless @config["max_width"]
        raise InvalidStorageConfig, 'Missing "max_height"' unless @config["max_height"]
      end

      def get_url_parts(url)
        match = url.match(/^(([a-z]+):|)(#{@config["public_url"]})\/(.+)$/)
        return match && {
          protocol: match[2],
          public_url: match[3],
          path: match[4]
        }
      end

      # Resizes the image if it doesn't fit on the server. Updates the name if
      # needed.
      # Returns { image: resized_image, name: resized_name }.
      def resize_to_fit(image, name)
        # Resize the image if it's larger than the max width/height.
        if image.width > @config["max_width"] || image.height > @config["max_height"]
          image.resize([image.width, @config["max_width"]].min, [image.height, @config["max_height"]].min)
          # Generate a new name.
          name = SnapImage::ImageNameUtils.get_resized_image_name(name, image.width, image.height)
        end
        { image: image, name: name }
      end
    end
  end
end
