module SnapImage
  class Server
    ACTIONS = ["generate_image", "sync_resource", "delete_resource_images", "list_resource_images"]
    RESOURCE_ID_REGEXP = /^[a-z0-9_-]+(\/[a-z0-9_-]+)*$/

    # Arguments:
    # * request:: Rack::Request
    def initialize(request, config)
      @request = request
      @config = config
      @storage = @config.storage
    end

    # Handles the request and returns a Rack::Response.
    def call
      @response = SnapImage::Response.new
      begin
        raise SnapImage::BadRequest if @request.bad_request?
        raise SnapImage::InvalidResourceIdentifier unless !!@request.json["resource_identifier"].match(SnapImage::Server::RESOURCE_ID_REGEXP)
        @response.content_type = @request.json["response_content_type"] if @request.json["response_content_type"]
        @response.template = @request.json["response_template"] if @request.json["response_template"]
        action = @request.json["action"]
        raise SnapImage::ActionNotImplemented unless ACTIONS.include?(action)
        @response = get_action_class(action).new(@config, @request, @response).call
      rescue SnapImage::BadRequest
        @response.set_bad_request
      rescue SnapImage::ActionNotImplemented
        @response.set_not_implemented
      rescue SnapImage::AuthorizationRequired
        @response.set_authorization_required
      rescue SnapImage::AuthorizationFailed
        @response.set_authorization_failed
      rescue SnapImage::InvalidImageIdentifier
        @response.set_invalid_image_identifier
      rescue SnapImage::InvalidResourceIdentifier
        @response.set_invalid_resource_identifier
      #rescue
        #@response.set_internal_server_error
      end
      @response.finish
    end

    private

    def get_action_class(action)
      klassname = action.split("_").map { |t| t.capitalize }.join("")
      SnapImage::ServerActions.const_get(klassname)
    end
  end
end
