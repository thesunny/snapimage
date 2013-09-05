require "spec_helper"

describe SnapImage::Local::Storage do
  before do
    @config = { "directory" => "/directory", "public_url" => "http://snapimage.com/public" }
    @storage = SnapImage::Local::Storage.new(@config)
  end

  describe "#store" do
    before do
      @file = double("file")
      FileUtils.stub(:mkdir_p)
    end

    it "stores the file" do
      File.should_receive(:open).with("/directory/abc/123/file.png", "wb").once
      @storage.store("file.png", @file, directory: "abc/123")
    end

    it "returns the public URL" do
      File.stub(:open)
      @storage.store("file.png", @file, directory: "abc/123").should eq "http://snapimage.com/public/abc/123/file.png"
    end
  end

  describe "#get_file_path" do
    it "returns a simple file path when the file doesn't exist" do
      File.stub(:exists?).and_return(false)
      @storage.send(:get_file_path, "abc/123", "pic.png").should eq "abc/123/pic.png"
    end

    it "returns the file path appended with (1) when only the file exists" do
      File.stub(:exists?).and_return(true)
      Dir.stub(:glob).and_return([])
      @storage.send(:get_file_path, "abc/123", "pic.png").should eq "abc/123/pic(1).png"
    end

    it "returns the file path appended with the next number when multiple files exist" do
      File.stub(:exists?).and_return(true)
      Dir.stub(:glob).and_return(["abc/123/pic(10).png", "abc/123/pic(2).png"])
      @storage.send(:get_file_path, "abc/123", "pic.png").should eq "abc/123/pic(11).png"
    end
  end
end
