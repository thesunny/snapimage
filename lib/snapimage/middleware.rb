module SnapImage
  # SnapImage API Rack Middleware to handle all SnapImage API calls.
  class Middleware
    # Arguments:
    # * app:: Rack application
    # * path:: The URL path to access the SnapImage API (defaults to "/snapimage_api")
    # * config:: Filename of the YAML or JSON config file or a config Hash
    def initialize(app, path = "/snapimage_api", config = nil)
      @app = app
      @path = path
      @config = SnapImage::Config.new(config)
    end

    def call(env)
      request = SnapImage::Request.new(env)
      if request.path_info == @path
        SnapImage::Server.new(request, @config).call
      else
        @app.call(env)
      end
    end
  end
end
