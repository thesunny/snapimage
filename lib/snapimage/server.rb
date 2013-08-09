module SnapImage
  class Server
    DIRECTORY_REGEXP = /^[a-z0-9_-]+(\/[a-z0-9_-]+)*$/
    FILENAME_REGEXP = /^[a-z0-9_-]+[.](gif|jpg|jpeg|png)$/

    # Arguments:
    # * request:: Rack::Request
    def initialize(request, config)
      @request = request
      @config = config
    end

    # Handles the request and returns a Rack::Response.
    def call
      @response = SnapImage::Response.new
      begin
        raise SnapImage::BadRequest if @request.bad_request?
        raise SnapImage::InvalidFilename unless @request.file.filename =~ SnapImage::Server::FILENAME_REGEXP
        raise SnapImage::InvalidDirectory unless @request["directory"] =~ SnapImage::Server::DIRECTORY_REGEXP
        raise SnapImage::FileTooLarge if @request.file.tempfile.size > @config["max_file_size"]
        directory = File.join(@config["directory"], @request["directory"])
        file_path = File.join(directory, @request.file.filename)
        # Make sure the directory exists.
        FileUtils.mkdir_p(directory)
        # Save the file.
        File.open(file_path, "wb") { |f| f.write(@request.file.tempfile.read) } unless File.exists?(file_path)
        @response.set_success(url: File.join(@config["public_url"], @request["directory"], @request.file.filename))
      rescue SnapImage::BadRequest
        @response.set_bad_request
      #rescue SnapImage::AuthorizationRequired
        #@response.set_authorization_required
      #rescue SnapImage::AuthorizationFailed
        #@response.set_authorization_failed
      rescue SnapImage::InvalidFilename
        @response.set_invalid_filename
      rescue SnapImage::InvalidDirectory
        @response.set_invalid_directory
      rescue SnapImage::FileTooLarge
        @response.set_file_too_large
      rescue
        @response.set_internal_server_error
      end
      @response.finish
    end
  end
end
