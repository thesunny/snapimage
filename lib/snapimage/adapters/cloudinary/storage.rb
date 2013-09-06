module SnapImage
  module Cloudinary
    class Storage
      def initialize(config)
        @config = config
      end

      # Stores the file in the given directory and returns the publicly
      # accessible URL.
      # Options:
      # * directory - directory to store the file in
      def store(filename, file, options = {})
        ext = File.extname(filename)
        basename = File.basename(filename, ext)
        public_id = "#{basename}_#{rand(9999)}"
        public_id = File.join(options[:directory], public_id) if options[:directory]
        response = ::Cloudinary::Uploader.upload(file, public_id: public_id)
        ::Cloudinary::Utils.cloudinary_url(public_id + ext)
      end
    end
  end
end
