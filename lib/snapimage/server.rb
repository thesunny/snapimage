module SnapImage
  class Server
    DIRECTORY_REGEXP = /^[a-z0-9_-]+(\/[a-z0-9_-]+)*$/i
    FILENAME_REGEXP = /^[^\/]+[.](gif|jpg|jpeg|png)$/i

    # Arguments:
    # * request:: Rack::Request
    def initialize(request, config, storage)
      @request = request
      @config = config
      @storage = storage
    end

    # Handles the request and returns a Rack::Response.
    def call
      # If the request is not an XHR, the response type should be text/html or
      # text/plain. This affects browsers like IE8/9 when performing uploads
      # through an iframe transport. If we return using text/json, the browser
      # attempts to download the file instead.
      @response = SnapImage::Response.new(content_type: @request.xhr? ? "text/json" : "text/html")
      begin
        raise SnapImage::BadRequest if @request.bad_request?
        raise SnapImage::InvalidFilename unless @request.file.filename =~ SnapImage::Server::FILENAME_REGEXP
        directory = @request["directory"] || "uncategorized"
        raise SnapImage::InvalidDirectory unless directory =~ SnapImage::Server::DIRECTORY_REGEXP
        raise SnapImage::FileTooLarge if @request.file.tempfile.size > @config["max_file_size"]
        url = @storage.store(@request.file.filename, @request.file.tempfile, directory: directory)
        @response.set_success(url: url)
      rescue SnapImage::BadRequest
        @response.set_bad_request
      rescue SnapImage::InvalidFilename
        @response.set_invalid_filename
      rescue SnapImage::InvalidDirectory
        @response.set_invalid_directory
      rescue SnapImage::FileTooLarge
        @response.set_file_too_large
      end
      @response.finish
    end
  end
end
