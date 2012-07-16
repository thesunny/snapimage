module SnapImage
  class Request < Rack::Request
    def bad_request?
      !(self.post? && self.POST["json"] && self.json["action"] && self.json["resource_identifier"])
    end

    # NOTE: Call bad_request? first to make sure there is json to parse.
    def json
      @json ||= JSON.parse(self.POST["json"])
    end

    # Returns a SnapImage::RequestFile which encapsulates the file that Rack
    # provides. Returns nil if there is no file.
    def file
      return nil unless self.POST["file"]
      @file ||= SnapImage::RequestFile.new(self.POST["file"])
    end
  end
end
