module SnapImage
  class Response < Rack::Response
    attr_accessor  :content_type, :template, :json

    def initialize(options = {})
      @content_type = options[:content_type] || "text/json"
      @template = options[:template] || "{{json}}"
      @json = {}
      super()
    end

    def set_success(info = {})
      info[:message] ||= "Success"
      @json = { status_code: 200 }.merge(info)
    end

    def set_bad_request
      @json = { status_code: 400, message: "Bad Request" }
    end

    def set_invalid_filename
      @json = { status_code: 403, message: "Invalid Filename" }
    end

    def set_invalid_directory
      @json = { status_code: 404, message: "Invalid Directory" }
    end

    def set_file_too_large
      @json = { status_code: 405, message: "File Too Large" }
    end

    def set_internal_server_error
      @json = { status_code: 500, message: "Internal Server Error" }
    end

    def finish
      write(@template.gsub(/{{json}}/, @json.to_json))
      self["Content-Type"] = @content_type
      super
    end
  end
end
