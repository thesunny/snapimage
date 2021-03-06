require "spec_helper"

describe SnapImage::Server do
  before do
    @request = double("request")
    @request.stub(:xhr?).and_return(true)
    @config = { "directory" => "/directory", "public_url" => "http://snapimage.com/public", "max_file_size" => 100 }
    @storage = double("storage")
    @server = SnapImage::Server.new(@request, @config, @storage)
  end

  describe "#call" do
    it "returns a bad request when the request is bad" do
      @request.stub(:bad_request?).and_return(true)
      response = @server.call
      response[0].should eq 200
      response[1]["Content-Type"].should eq "text/json"
      response[2].body.should eq ['{"status_code":400,"message":"Bad Request"}']
    end

    it "returns invalid filename when the filename is invalid" do
      @request.stub(:bad_request?).and_return(false)
      file = double("file")
      file.stub(:filename).and_return("abc123.txt")
      @request.stub(:file).and_return(file)
      response = @server.call
      response[0].should eq 200
      response[1]["Content-Type"].should eq "text/json"
      response[2].body.should eq ['{"status_code":403,"message":"Invalid Filename"}']
    end

    it "returns invalid directory when the directory is invalid" do
      @request.stub(:bad_request?).and_return(false)
      file = double("file")
      file.stub(:filename).and_return("abc123.png")
      @request.stub(:file).and_return(file)
      @request.stub(:[]).with("directory").and_return("abc?123")
      response = @server.call
      response[0].should eq 200
      response[1]["Content-Type"].should eq "text/json"
      response[2].body.should eq ['{"status_code":404,"message":"Invalid Directory"}']
    end

    it "returns file too large when the file is too large" do
      @request.stub(:bad_request?).and_return(false)
      tempfile = double("tempfile")
      tempfile.stub(:size).and_return(200)
      file = double("file")
      file.stub(:filename).and_return("abc123.png")
      file.stub(:tempfile).and_return(tempfile)
      @request.stub(:file).and_return(file)
      @request.stub(:[]).with("directory").and_return("abc/123")
      response = @server.call
      response[0].should eq 200
      response[1]["Content-Type"].should eq "text/json"
      response[2].body.should eq ['{"status_code":405,"message":"File Too Large"}']
    end

    it "returns success when the file is saved" do
      @request.stub(:bad_request?).and_return(false)
      tempfile = double("tempfile")
      tempfile.stub(:size).and_return(50)
      file = double("file")
      file.stub(:filename).and_return("abc123.png")
      file.stub(:tempfile).and_return(tempfile)
      @request.stub(:file).and_return(file)
      @request.stub(:[]).with("directory").and_return("abc/123")
      @storage.should_receive(:store).with("abc123.png", tempfile, directory: "abc/123").and_return("http://snapimage.com/public/abc/123/abc123.png")
      response = @server.call
      response[0].should eq 200
      response[1]["Content-Type"].should eq "text/json"
      response[2].body.should eq ['{"status_code":200,"url":"http://snapimage.com/public/abc/123/abc123.png","message":"Success"}']
    end

    it "returns success when uppercase" do
      @request.stub(:bad_request?).and_return(false)
      tempfile = double("tempfile")
      tempfile.stub(:size).and_return(50)
      file = double("file")
      file.stub(:filename).and_return("abc123.PNG")
      file.stub(:tempfile).and_return(tempfile)
      @request.stub(:file).and_return(file)
      @request.stub(:[]).with("directory").and_return("ABC/123")
      @storage.should_receive(:store).with("abc123.PNG", tempfile, directory: "ABC/123").and_return("http://snapimage.com/public/ABC/123/abc123.PNG")
      response = @server.call
      response[0].should eq 200
      response[1]["Content-Type"].should eq "text/json"
      response[2].body.should eq ['{"status_code":200,"url":"http://snapimage.com/public/ABC/123/abc123.PNG","message":"Success"}']
    end

    it "returns content type of text/html when non-XHR" do
      @request.stub(:xhr?).and_return(false)
      @request.stub(:bad_request?).and_return(false)
      tempfile = double("tempfile")
      tempfile.stub(:size).and_return(50)
      file = double("file")
      file.stub(:filename).and_return("abc123.png")
      file.stub(:tempfile).and_return(tempfile)
      @request.stub(:file).and_return(file)
      @request.stub(:[]).with("directory").and_return("abc/123")
      @storage.should_receive(:store).with("abc123.png", tempfile, directory: "abc/123").and_return("http://snapimage.com/public/abc/123/abc123.png")
      response = @server.call
      response[0].should eq 200
      response[1]["Content-Type"].should eq "text/html"
      response[2].body.should eq ['{"status_code":200,"url":"http://snapimage.com/public/abc/123/abc123.png","message":"Success"}']
    end

    it "uses the default directory when none is given" do
      @request.stub(:bad_request?).and_return(false)
      tempfile = double("tempfile")
      tempfile.stub(:size).and_return(50)
      file = double("file")
      file.stub(:filename).and_return("abc123.png")
      file.stub(:tempfile).and_return(tempfile)
      @request.stub(:file).and_return(file)
      @request.stub(:[]).with("directory").and_return(nil)
      @storage.should_receive(:store).with("abc123.png", tempfile, directory: "uncategorized").and_return("http://snapimage.com/public/uncategorized/abc123.png")
      response = @server.call
      response[0].should eq 200
      response[1]["Content-Type"].should eq "text/json"
      response[2].body.should eq ['{"status_code":200,"url":"http://snapimage.com/public/uncategorized/abc123.png","message":"Success"}']
    end
  end
end
