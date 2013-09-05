module SnapImage
  module Local
    class Config
      def initialize(config)
        @config = config
      end

      def validate_config
        raise SnapImage::InvalidConfig, 'Missing "directory"' unless @config["directory"]
        raise SnapImage::InvalidConfig, 'Missing "public_url"' unless @config["public_url"]
      end
    end
  end
end
