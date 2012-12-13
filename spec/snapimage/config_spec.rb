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
      c["directory"].should eq "/path/to/directory"
      c["max_file_size"].should eq 100
    end

    it "returns the config from a JSON file" do
      config = SnapImage::Config.new(File.join(RSpec.root, "support/assets/config.json"))
      c = config.get_config
      c["directory"].should eq "/path/to/directory"
      c["max_file_size"].should eq 100
    end
  end

  describe "#[]" do
    before do
      @config = SnapImage::Config.new(File.join(RSpec.root, "support/assets/config.yml"))
    end

    it "returns the value when the key exists" do
      @config["directory"].should eq "/path/to/directory"
    end

    it "returns nil when the key does not exist" do
      @config["random"].should be_nil
    end
  end
end
