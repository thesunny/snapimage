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
        basename = File.basename(filename, ext)
        public_id = "#{basename}(#{rand(9999)})"
        response = ::Cloudinary::Uploader.upload(file, public_id: public_id)
        ::Cloudinary::Utils.cloudinary_url(public_id + ext)
      end
    end
  end
end
