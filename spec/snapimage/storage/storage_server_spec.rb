require "spec_helper"

describe SnapImage::StorageServer::Base do
  before do
    @image_path = File.join(RSpec.root, "support/assets/stub-1x1.png")
    class TestServer < SnapImage::StorageServer::Base; end
    @server = TestServer.new(
      "name" => "Test",
      "public_url" => "//example.com/storage",
      "max_width" => 1024,
      "max_height" => 2048
    )
  end

  describe "url_regexp" do
    before do
      @regexp = @server.url_regexp
    end

    it "matches urls handled by the storage server" do
      "http://example.com/storage/image.png".match(@regexp).should_not be_nil
      "https://example.com/storage/image.png".match(@regexp).should_not be_nil
      "http://example.com/storage/sub/dir/image.png".match(@regexp).should_not be_nil
      "http://example.com/storage/sub/dir/image.gif".match(@regexp).should_not be_nil
      "http://example.com/storage/sub/dir/image.jpg".match(@regexp).should_not be_nil
    end

    it "does not match urls that are not handled by the storage server" do
      "http://other.com/storage/image.png".match(@regexp).should be_nil
      "http://example.com/storage/image.jpeg".match(@regexp).should be_nil
      "http://example.com/storage.png".match(@regexp).should be_nil
    end
  end

  describe "#local?" do
    it "returns true when the url is local" do
      @server.local?("http://example.com/storage/abc123/image.png").should be_true
    end

    it "returns false when the url is not local" do
      @server.local?("http://another.com/images/abc123/image.png").should be_false
    end

    it "returns false when the url is just the public url" do
      @server.local?("http://example.com/storage").should be_false
      @server.local?("http://example.com/storage/").should be_false
    end
  end

  describe "#get_url_parts" do
    it "returns nil when the url does not match the public url" do
      @server.send(:get_url_parts, "http://another.com/storage/abc123/image.png").should be_nil
    end

    it "returns the parts when the url matches the public url" do
      parts = @server.send(:get_url_parts, "http://example.com/storage/abc123/image.png")
      parts[:protocol].should eq "http"
      parts[:public_url].should eq "//example.com/storage"
      parts[:path].should eq "abc123/image.png"
    end

    it "returns the parts when the url has no protocol" do
      parts = @server.send(:get_url_parts, "//example.com/storage/abc123/image.png")
      parts[:protocol].should be_nil
      parts[:public_url].should eq "//example.com/storage"
      parts[:path].should eq "abc123/image.png"
    end
  end

  describe "#resize_to_fit" do
    before do
      @image = SnapImage::Image.from_blob(File.new(@image_path, "rb").read)
    end

    it "returns the original image and name when the image fits" do
      result = @server.send(:resize_to_fit, @image, "image")
      result[:image].should be @image
      result[:name].should eq "image"
    end

    it "returns the resized image and name given a base image" do
      @image.resize(2048, 100, false)
      result = @server.send(:resize_to_fit, @image, "12345678-2048x100.png")
      result[:image].width.should eq 1024
      result[:image].height.should eq 50
      result[:name].should eq "12345678-1024x50.png"
    end

    it "returns the resized image and name given a modified image" do
      @image.resize(2048, 100, false)
      result = @server.send(:resize_to_fit, @image, "12345678-1x1-0x0x1x1-2048x100-0.png")
      result[:image].width.should eq 1024
      result[:image].height.should eq 50
      result[:name].should eq "12345678-1x1-0x0x1x1-1024x50-0.png"
    end
  end
end
