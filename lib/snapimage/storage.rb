module SnapImage
  class Storage
    extend Forwardable
    def_delegators :@storage, :store

    def initialize(config)
      @storage = SnapImage.const_get(config["adapter"].capitalize).const_get("Storage").new(config)
    end
  end
end
