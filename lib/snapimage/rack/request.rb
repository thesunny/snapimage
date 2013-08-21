module SnapImage
  class Request < Rack::Request
    def bad_request?
      !(self.post? && self.POST["file"])
    end

    # Returns a SnapImage::RequestFile which encapsulates the file that Rack
    # provides. Returns nil if there is no file.
    def file
      return nil unless self.POST["file"]
      @file ||= SnapImage::RequestFile.new(self.POST["file"])
    end
  end
end
