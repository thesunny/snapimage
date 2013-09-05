module SnapImage
  module Cloudinary
    class Config
      def initialize(config)
        @config = config
      end

      def validate_config
        # Nothing to validate.
      end
    end
  end
end
