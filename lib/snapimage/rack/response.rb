module SnapImage
  class Response < Rack::Response
    attr_accessor  :content_type, :template, :json

    def initialize(options = {})
      @content_type = options[:content_type] || "text/json"
      @template = options[:template] || "{{json}}"
      @json = {}
      super
    end

    def set_success(info = {})
      info[:message] ||= "Success"
      @json = { status_code: 200 }.merge(info)
    end

    def set_bad_request
      @json = { status_code: 400, message: "Bad Request" }
    end

    def set_authorization_required
      @json = { status_code: 401, message: "Authorization Required" }
    end

    def set_authorization_failed
      @json = { status_code: 402, message: "Authorization Failed" }
    end

    def set_invalid_image_identifier
      @json = { status_code: 403, message: "Invalid Image Identifier" }
    end

    def set_invalid_resource_identifier
      @json = { status_code: 404, message: "Invalid Resource Identifier" }
    end

    def set_internal_server_error
      @json = { status_code: 500, message: "Internal Server Error" }
    end

    def set_not_implemented
      @json = { status_code: 501, message: "Not Implemented" }
    end

    def finish
      self.body = [@template.gsub(/{{json}}/, @json.to_json)]
      self["Content-Type"] = @content_type
      super
    end
  end
end
