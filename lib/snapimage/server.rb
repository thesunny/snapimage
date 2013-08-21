module SnapImage
  class Server
    DIRECTORY_REGEXP = /^[a-z0-9_-]+(\/[a-z0-9_-]+)*$/
    FILENAME_REGEXP = /^[^\/]+[.](gif|jpg|jpeg|png)$/

    # Arguments:
    # * request:: Rack::Request
    def initialize(request, config)
      @request = request
      @config = config
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
        file_directory = File.join(@config["directory"], directory)
        file_path = get_file_path(file_directory, @request.file.filename)
        # Make sure the directory exists.
        FileUtils.mkdir_p(file_directory)
        # Save the file.
        File.open(file_path, "wb") { |f| f.write(@request.file.tempfile.read) } unless File.exists?(file_path)
        @response.set_success(url: File.join(@config["public_url"], directory, File.basename(file_path)))
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

    private

    # Gets the file path from the given directory and filename.
    # If the file path already exists, appends a (1) to the basename.
    # If there are already multiple files, appends the next (num) in the
    # sequence.
    def get_file_path(directory, filename)
      file_path = File.join(directory, filename)
      if File.exists?(file_path)
        ext = File.extname(filename)
        basename = File.basename(filename, ext)
        files = Dir.glob(File.join(directory, "#{basename}([0-9]*)#{ext}"))
        if files.size == 0
          num = 1
        else
          num = files.map { |f| f.match(/\((\d+)\)/)[1].to_i }.sort.last + 1
        end
        file_path = "#{File.join(directory, basename)}(#{num})#{ext}"
      end
      file_path
     end
  end
end
