require "spec_helper"

describe SnapImage::StorageServer::Local do
  before do
    @local_root = File.join(RSpec.root, "storage")
    @image_path = File.join(RSpec.root, "support/assets/stub-1x1.png")
    @server = SnapImage::StorageServer::Local.new(
      "name" => "Test",
      "public_url" => "//example.com/storage",
      "local_root" => @local_root,
      "max_width" => 1024,
      "max_height" => 2048
    )
  end

  after do
    FileUtils.rm_rf(@local_root)
  end

  describe "#store_file" do
    before do
      SnapImage::ImageNameUtils.stub(:generate_image_name).and_return("test_image.png")
      @file = File.new(@image_path, "rb")
      @server.store_file(@file, "png", "abc/123")
    end

    it "copies the contents of the file" do
      contents = File.new(File.join(@local_root, "abc/123/test_image.png"), "rb").read
      blob = SnapImage::Image.from_blob(File.new(@image_path, "rb").read).blob
      contents.should eq blob
    end
  end

  describe "#get" do
    before do
      SnapImage::ImageNameUtils.stub(:generate_image_name).and_return("test_image.png")
      @server.store_file(File.new(@image_path), "png", "abc/123")
    end

    it "raises an error when the file doesn't exist" do
      expect { @server.get("http://example.com/storage/abc/123/test_image.gif") }.should raise_error SnapImage::FileDoesNotExist
    end

    it "returns a SnapImage::Image" do
      image = @server.get("http://example.com/storage/abc/123/test_image.png")
      image.is_a?(SnapImage::Image).should be_true
    end
  end

  describe "#store" do
    before do
      SnapImage::ImageNameUtils.stub(:generate_image_name).and_return("test_image.png")
      @image = @server.send(:store, SnapImage::Image.from_blob(File.new(@image_path, "rb").read), "test_image.png", "abc/123")
    end

    it "creates a new file in the storage" do
      File.exists?(File.join(@local_root, "abc/123/test_image.png")).should be_true
    end

    it "writes the contents to the file" do
      contents = File.new(File.join(@local_root, "abc/123/test_image.png"), "rb").read
      blob = SnapImage::Image.from_blob(File.new(@image_path, "rb").read).blob
      contents.should eq blob
    end

    it "returns the image" do
      @image.is_a?(SnapImage::Image).should be_true
      @image.public_url.should eq "//example.com/storage/abc/123/test_image.png"
    end
  end

  describe "#root" do
    it "creates the root when it doesn't exist" do
      @server.send(:root)
      File.directory?(@local_root)
    end

    it "returns the root" do
      @server.send(:root).should eq @local_root
    end
  end

  describe "#get_local_path_parts" do
    it "returns nil when the the path is not a local path" do
      @server.send(:get_local_path_parts, "some/random/path/image.png").should be_nil
    end

    it "returns the parts when the path is a local path" do
      parts = @server.send(:get_local_path_parts, File.join(@local_root, "abc/123/image.png"))
      parts[:resource_id].should eq "abc/123"
      parts[:filename].should eq "image.png"
    end
  end

  describe "#local_path_to_public_url" do
    it "returns the public url corresponding to the local path" do
      local_path = File.join(@local_root, "abc/123/image.png")
      @server.send(:local_path_to_public_url, local_path).should eq "//example.com/storage/abc/123/image.png"
    end
  end

  describe "#public_url_to_local_path" do
    it "returns the local path corresponding to the public url" do
      url = "http://example.com/storage/abc/123/image.png"
      @server.send(:public_url_to_local_path, url).should eq File.join(@local_root, "abc/123/image.png")
    end
  end

  describe "#get_resource_filenames" do
    before do
      @old_local_root = @local_root
      @local_root = File.join(File.expand_path(File.dirname(__FILE__)), "assets/local")
      @server = SnapImage::StorageServer::Local.new(
        "name" => "Test",
        "public_url" => "//example.com/storage",
        "local_root" => @local_root,
        "max_width" => 1024,
        "max_height" => 2048
      )
    end

    after do
      @local_root = @old_local_root
    end

    it "returns only images for the given resource id" do
      filenames = @server.send(:get_resource_filenames, "resource_1")
      filenames.size.should eq 3
      filenames.include?(File.join(@local_root, "resource_1/12345678-1x1.png")).should be_true
      filenames.include?(File.join(@local_root, "resource_1/12345678-1x1-0x0x1x1-300x200-0.jpg")).should be_true
      filenames.include?(File.join(@local_root, "resource_1/12345678-1x1-0x0x1x1-1x1-1.gif")).should be_true
    end
  end

  describe "#file_modified_before_timestamp??" do
    it "returns true when no timestamp is given" do
      @server.send(:file_modified_before_timestamp?, @image_path).should be_true
    end

    it "returns true when the file was modified before the timestamp" do
      timestamp = DateTime.parse(File.mtime(@image_path).iso8601) + 100
      @server.send(:file_modified_before_timestamp?, @image_path, timestamp).should be_true
    end

    it "returns false when file was not modified before the timestamp" do
      timestamp = DateTime.parse(File.mtime(@image_path).iso8601)
      @server.send(:file_modified_before_timestamp?, @image_path, timestamp).should be_false
    end
  end
end
