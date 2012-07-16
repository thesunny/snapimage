require "spec_helper"

describe SnapImage::Storage do
  before do
    @local_root = File.join(RSpec.root, "storage")
    @storage = SnapImage::Storage.new(
      [{
        "name" => "test",
        "type" => "LOCAL",
        "local_root" => @local_root,
        "public_url" => "//example.com/storage"
      }],
      "test",
      1024,
      2048
    )
  end

  after do
    FileUtils.rm_rf(@local_root)
  end

  describe "#servers" do
    it "creates a hash of the servers from the configs" do
      servers = @storage.send(:servers)
      servers["test"].should be
    end
  end

  describe "#get_server_class" do
    it "raises when the type is not supported" do
      expect { @storage.send(:get_server_class, "test") }.should raise_error SnapImage::InvalidStorageConfig
    end

    it "returns the correct class" do
      @storage.send(:get_server_class, "LOCAL").should eq SnapImage::StorageServer::Local
    end
  end

  describe "#get_server_by_url" do
    it "returns the server when there is a match" do
      @storage.send(:get_server_by_url, "http://example.com/storage/abc123/image.png").name.should eq "test"
    end

    it "returns nil when there is no match" do
      @storage.send(:get_server_by_url, "http://another.com/storage/abc123/image.png").should be_nil
    end
  end
end
