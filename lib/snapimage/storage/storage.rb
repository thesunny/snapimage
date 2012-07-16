module SnapImage
  class Storage
    TYPES = %w{LOCAL}
    FILE_TYPES = %w{png jpg gif}


    def initialize(server_configs, primary_server_name, max_width, max_height)
      @server_configs = server_configs
      # TODO: Remove this once we figure out how to handle multiple servers.
      raise SnapImage::InvalidConfig, "Only one storage server can be specified at the moment" unless @server_configs.size == 1
      @primary_server_name = primary_server_name
      @max_width = max_width
      @max_height = max_height
    end

    # Returns an array of all the url regexps that are handled by the storage.
    def url_regexps
      @url_regexps ||= servers.values.map { |s| s.url_regexp }
    end

    # Returns true if the url is local to the storage. False otherwise.
    def local?(url)
      !!get_server_by_url(url)
    end

    # Adds the image to the storage and returns the public url to the file.
    # Arguments:
    # * file:: SnapImage::RequestFile
    # * resource_id:: Resource identifier
    def add_upload(file, resource_id)
      raise UnknownFileType, "Unknown file type for upload: #{file.type}" unless FILE_TYPES.include?(file.type)
      primary_server.store_file(file.file, file.type, resource_id)
    end

    # Adds the image to the storage from the url.
    # If the image is from a storage server, nothing happens.
    # If the image is from another place, the image is downloaded and added to
    # the primary storage server.
    # The image is returned.
    # Arguments:
    # * url:: A full url to the image
    # * resource_id:: Resource identifier
    def add_url(url, resource_id)
      # If the url is local, then the image should already be in the storage.
      return get(url) if get_server_by_url(url)
      type = ImageNameUtils.get_image_type(url)
      raise UnknownFileType, "Unknown file type for upload: #{type}" unless FILE_TYPES.include?(type)
      primary_server.store_url(url, type, resource_id)
    end

    # Adds the image to the storage.
    # Arguments:
    # * image:: SnapImage::Image object
    # * name:: Name of the image
    # * resource_id:: Resource identifier
    def add_image(image, name, resource_id)
      primary_server.store_image(image, name, resource_id)
    end

    # Returns a SnapImage::Image using the url.
    def get(url)
      get_server_by_url(url).get(url)
    end

    # Returns all the image urls for the given resource in the storage.
    # Arguments:
    # * resource_id:: Filter by resource identifier
    # * timestamp:: Only images that were updated before the DateTime
    def get_resource_urls(resource_id, timestamp = nil)
      servers.values.inject([]) { |urls, server| urls + server.get_resource_urls(resource_id, timestamp) }
    end

    # Deletes the given url from the storage.
    # Arguments:
    # * url:: URL to delete
    def delete(url)
      get_server_by_url(url).delete(url)
    end

    # Deletes all the image related to the resource.
    # Arugments:
    # * resource_id:: Resource identifier
    def delete_resource_images(resource_id)
      deleted_urls = []
      servers.each do |name, server|
        deleted_urls += server.delete_resource_images(resource_id)
      end
      deleted_urls
    end

    private

    def servers
      return @servers if @servers
      @servers = {}
      @server_configs.each do |config|
        type = config["type"]
        @servers[config["name"]] = get_server_class(type).new(config.merge("max_width" => @max_width, "max_height" => @max_height))
      end
      @servers
    end

    def primary_server
      servers[@primary_server_name]
    end

    def get_server_class(type)
      raise SnapImage::InvalidStorageConfig, "Storage server type not supported: #{type}" unless TYPES.include?(type)
      klassname = type.downcase.split("_").map { |t| t.capitalize }.join("")
      SnapImage::StorageServer.const_get(klassname)
    end

    def get_server_by_url(url)
      servers.each do |name, server|
        return server if server.local?(url)
      end
      return nil
    end
  end
end
