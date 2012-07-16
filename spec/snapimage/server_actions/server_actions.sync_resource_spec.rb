require "spec_helper"

describe SnapImage::ServerActions::SyncResource do
  before do
    @image_path = File.join(RSpec.root, "support/assets/stub-300x200.png")
    @storage = double("storage")
    @config = { "max_width" => 1024, "max_height" => 2048 }
    @config.stub(:storage).and_return(@storage)
    @request = double("request")
    @response = double("response")
    @sync_resource = SnapImage::ServerActions::SyncResource.new(@config, @request, @response)
  end

  describe "#request_valid?" do
    it "returns false when content is not valid" do
      @sync_resource.stub(:content_valid?).and_return(false)
      @sync_resource.send(:request_valid?).should be_false
    end

    it "returns false when sync_date_time is not defined" do
      @sync_resource.stub(:content_valid?).and_return(true)
      @request.stub(:json).and_return({})
      @sync_resource.send(:request_valid?).should be_false
    end

    it "returns true when the request is valid" do
      @request.stub(:json).and_return({"sync_date_time" => DateTime.now.iso8601})
      @sync_resource.stub(:content_valid?).and_return(true)
      @sync_resource.send(:request_valid?).should be_true
    end
  end

  describe "#content_valid?" do
    it "returns false when content is not defined" do
      @request.stub(:json).and_return({})
      @sync_resource.send(:content_valid?).should be_false
    end

    it "returns false when content is not a hash" do
      @request.stub(:json).and_return({"content" => "content"})
      @sync_resource.send(:content_valid?).should be_false
    end

    it "returns false when content is empty" do
      @request.stub(:json).and_return({"content" => {}})
      @sync_resource.send(:content_valid?).should be_false
    end

    it "returns true when content is valid" do
      @request.stub(:json).and_return({"content" => {"body" => "test"}})
      @sync_resource.send(:content_valid?).should be_true
    end
  end

  describe "#get_content" do
    it "returns all the content concatenated" do
      @request.stub(:json).and_return({"content" => {"first" => "hello", "second" => "world"}})
      @sync_resource.send(:get_content).should eq "helloworld"
    end
  end

  describe "#urls_to_keep" do
    it "returns all urls that match" do
      @storage.stub(:url_regexps).and_return([
        /(\/\/example\.com\/storage\/.+?\.(png|gif|jpg))/,
        /\/\/snapeditor\.com\/.+?\.(png|gif|jpg)/,
        /\/\/my-bucket\.s3\.amazonaws\.com\/my-images\/.+?\.(png|gif|jpg)/
      ])
      url_1 = "http://example.com/storage/abc/123/12345678-1024x768.png"
      url_2 = "http://snapeditor.com/abc/123/12345678-1024x768-10x40x200x300-400x500-0.gif"
      url_3 = "//my-bucket.s3.amazonaws.com/my-images/abc/123/12345678-1024x768-10x40x200x300-400x500-0.jpg"
      url_4 = "//my-bucket.s3.amazonaws.com/my-images/abc/123/12345678-1024x768-10x40x200x300-400x500-1.jpg"
      @sync_resource.stub(:get_content).and_return(
      <<-CONTENT
        This is some fake content with images. <img src="#{url_1}" /><img src="http://example.com/abc/123/image.png" />
        Some more ["#{url_2}"] but maybe not this http://snapeditor.com/.
        #{url_3} and //my-bucket.s3.amazonaws.com/my-images/abc/123/image.jpeg and #{url_4}
      CONTENT
      )
      keep = @sync_resource.send(:urls_to_keep)
      keep.size.should eq 7
      keep.include?(url_1)
      keep.include?(url_2)
      keep.include?(url_3)
      keep.include?(url_4)
      keep.include?("http://snapeditor.com/abc/123/12345678-1024x768.gif")
      keep.include?("//my-bucket.s3.amazonaws.com/my-images/abc/123/12345678-1024x768.jpg")
      keep.include?("//my-bucket.s3.amazonaws.com/my-images/abc/123/12345678-1024x768.jpg")
    end
  end
end
