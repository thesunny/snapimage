module SnapImage
  class RequestFile
    # The file comes through Rack's request's POST like this:
    # {
    #   :filename=>"jpeg.jpeg",
    #   :type=>"image/jpeg",
    #   :name=>"file", 
    #   :tempfile=>#<File:/tmp/RackMultipart20120628-19317-1w4ouxp>,
    #   :head=>"Content-Disposition: form-data; name=\"file\"; filename=\"jpeg.jpeg\"\r\nContent-Type: image/jpeg\r\n"}
    # }
    def initialize(file)
      @file = file
    end

    def file
      @file[:tempfile]
    end

    def type
      return @type if @type
      @type = @file[:type].split("/").last
      @type = "jpg" if type == "jpeg"
      @type
    end
  end
end
