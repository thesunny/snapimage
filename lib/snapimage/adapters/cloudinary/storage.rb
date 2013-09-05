module SnapImage
  module Cloudinary
    class Storage
      def initialize(config)
        @config = config
      end

      # Stores the file in the given directory and returns the publicly
      # accessible URL.
      # Options: none
      def store(filename, file, options = {})
        ext = File.extname(filename)
        response = Cloudinary::Uploader.upload(file, use_filename: true)
        Cloudinary::Utils.cloudinary_url(response["public_id"] + ext)
      end
    end
  end
end
