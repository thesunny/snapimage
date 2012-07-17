module SnapImage
  module StorageServer
    class Local < SnapImage::StorageServer::Base
      def validate_config
        super
        raise InvalidStorageConfig, 'Missing "local_root"' unless @config["local_root"]
      end

      def store_file(file, type, resource_id)
        image = SnapImage::Image.from_blob(file.read)
        name = SnapImage::ImageNameUtils.generate_image_name(image.width, image.height, type)
        store(image, name, resource_id)
      end

      def store_url(url, type, resource_id)
        image = SnapImage::Image.from_blob(URI.parse(url).read)
        name = SnapImage::ImageNameUtils.generate_image_name(image.width, image.height, type)
        store(image, name, resource_id)
      end

      def store_image(image, name, resource_id)
        store(image, name, resource_id)
      end

      def get(url)
        path = public_url_to_local_path(url)
        raise SnapImage::FileDoesNotExist, "Missing file: #{path}" unless File.exists?(path)
        SnapImage::Image.from_path(path, url)
      end

      def get_resource_urls(resource_id, timestamp = nil)
        urls = []
        get_resource_filenames(resource_id).each do |filename|
          urls.push(local_path_to_public_url(filename)) if file_modified_before_timestamp?(filename, timestamp)
        end
        urls
      end

      def delete(url)
        path = public_url_to_local_path(url)
        raise SnapImage::FileDoesNotExist, "Missing file: #{path}" unless File.exists?(path)
        File.delete(path)
      end

      def delete_resource_images(resource_id)
        deleted_urls = get_resource_urls(resource_id)
        FileUtils.rm_rf(File.join(root, resource_id)) if deleted_urls.size > 0
        deleted_urls
      end

      private

      # Stores the image and returns a SnapImage::Image object.
      # If the image does not fit within the server max width/height, the image
      # is resized and the modified image is returned.
      # Arguments:
      # * image:: SnapImage::Image to store
      # * name:: Suggested name to use
      # * resource_id:: Resource identifier
      def store(image, name, resource_id)
        result = resize_to_fit(image, name)
        image = result[:image]
        name = result[:name]

        # Generate the filename and public url.
        local_path = File.join(resource_id, name)
        image.public_url = "#{File.join(@config["public_url"], local_path)}"

        # Store the file.
        path = File.join(root, local_path)
        # Ensure the directory exists accounting for the resource_id.
        dir = File.dirname(path)
        FileUtils.mkdir_p(dir)
        # Write the file to the storage.
        File.open(path, "wb") { |f| f.write(image.blob) }

        # Return the image.
        image
      end

      def root
        unless @root_exists
          FileUtils.mkdir_p(@config["local_root"]) unless File.directory?(@config["local_root"])
          @root_exists = true
        end
        @config["local_root"]
      end

      def get_local_path_parts(path)
        match = path.match(/#{root}\/(.+)\/([^\/]+\.(png|jpg|gif))/)
        return match && {
          resource_id: match[1],
          filename: match[2]
        }
      end

      def local_path_to_public_url(path)
        parts = get_local_path_parts(path)
        "#{File.join(@config["public_url"], parts[:resource_id], parts[:filename])}"
      end

      def public_url_to_local_path(url)
        parts = get_url_parts(url)
        path = File.join(root, parts[:path])
      end

      def get_resource_filenames(resource_id)
        Dir.glob(File.join(root, resource_id, "/**/*.{png,jpg,gif}"))
      end

      # Returns true if no timestamp is given or the file was modified before
      # the timestamp.
      def file_modified_before_timestamp?(filename, timestamp = nil)
        # File.mtime returns a Time object. Convert it to a DateTime because
        # timestamp is a DateTime.
        !timestamp || File.mtime(filename).to_datetime < timestamp
      end
    end
  end
end
