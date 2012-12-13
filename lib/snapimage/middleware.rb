module SnapImage
  # SnapImage API Rack Middleware to handle all SnapImage API calls.
  class Middleware
    # Arguments:
    # * app:: Rack application
    # * options:: Options for the middleware
    #
    # Options:
    # * path:: The URL path to access the SnapImage API (defaults to "/snapimage_api")
    # * config:: Filename of the YAML or JSON config file or a config Hash # (defaults to "config/snapimage_config.yml")
    def initialize(app, options = {})
      @app = app
      @path = options[:path] || "/snapimage_api"
      @config = SnapImage::Config.new(options[:config] || "config/snapimage_config.yml")
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
