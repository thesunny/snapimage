module SnapImage
  class Config
    # Arguments:
    # * config:: Filename of the YAML or JSOn file to load or a config Hash.
    #
    # NOTE: All keys are strings, not symbols.
    def initialize(config)
      @raw_config = config
    end

    def validate_config
      raise SnapImage::InvalidConfig, 'Missing "primary_storage_server"' unless @config["primary_storage_server"]
      raise SnapImage::InvalidConfig, 'Missing "storage_servers"' unless @config["storage_servers"]
      raise SnapImage::InvalidConfig, '"storage_servers" must be an array' unless @config["storage_servers"].is_a? Array
    end

    def set_config_defaults
      @config["max_width"] ||= 1024
      @config["max_height"] ||= 2048
    end

    def get_config
      return @config if @config
      @config = @raw_config
      if @raw_config.is_a? String
        ext = File.extname(@raw_config)
        case ext
        when ".yml", ".yaml"
          @config = YAML::load(File.open(@raw_config))
        when ".json"
          @config = JSON::parse(File.read(@raw_config))
        else
          raise SnapImage::UnknownFileType, "Unknown filetype. Expecting .yaml, .yml, or .json: #{@raw_config}"
        end
      end

      raise SnapImage::UnknownConfigType, "Unknown config type. Expecting a filename or hash: #{@config}" unless @config.is_a? Hash
      validate_config
      set_config_defaults
      @config
    end

    def [](key)
      get_config[key]
    end

    def storage
      @storage ||= SnapImage::Storage.new(get_config["storage_servers"], get_config["primary_storage_server"], get_config["max_width"], get_config["max_height"])
    end
  end
end
