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
      raise SnapImage::InvalidConfig, 'Missing "directory"' unless @config["directory"]
    end

    def set_config_defaults
      @config["max_file_size"] ||= 10485760 # 10MB
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
  end
end
