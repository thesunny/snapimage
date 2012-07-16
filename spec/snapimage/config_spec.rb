require "spec_helper"

describe SnapImage::Config do
  describe "#get_config" do
    it "raises when the config is not a String or Hash" do
      config = SnapImage::Config.new(1)
      expect { config.get_config }.to raise_error SnapImage::UnknownConfigType
    end

    it "raises when the file is not YAML or JSON" do
      config = SnapImage::Config.new("config.txt")
      expect { config.get_config }.to raise_error SnapImage::UnknownFileType
    end

    it "raises when the file cannot be found" do
      config = SnapImage::Config.new("config.yml")
      expect { config.get_config }.to raise_error Errno::ENOENT
    end

    it "returns the config from a YAML file" do
      config = SnapImage::Config.new(File.join(RSpec.root, "support/assets/config.yml"))
      c = config.get_config
      c["security_salt"].should eq "abc123"
      c["storage_servers"].length.should eq 2
      c["storage_servers"][0]["name"].should eq "storage 1"
      c["storage_servers"][0]["type"].should eq "test"
      c["storage_servers"][1]["name"].should eq "storage 2"
      c["storage_servers"][1]["type"].should eq "test"
    end

    it "returns the config from a JSON file" do
      config = SnapImage::Config.new(File.join(RSpec.root, "support/assets/config.json"))
      c = config.get_config
      c["security_salt"].should eq "abc123"
      c["storage_servers"].length.should eq 2
      c["storage_servers"][0]["name"].should eq "storage 1"
      c["storage_servers"][0]["type"].should eq "test"
      c["storage_servers"][1]["name"].should eq "storage 2"
      c["storage_servers"][1]["type"].should eq "test"
    end
  end

  describe "#[]" do
    before do
      @config = SnapImage::Config.new(File.join(RSpec.root, "support/assets/config.yml"))
    end

    it "returns the value when the key exists" do
      @config["security_salt"].should eq "abc123"
    end

    it "returns nil when the key does not exist" do
      @config["random"].should be_nil
    end
  end
end
