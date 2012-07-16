require "spec_helper"
require "rack/test"

describe "Modify" do
  include Rack::Test::Methods

  before do
    @local_root = File.join(RSpec.root, "storage")
    @image_path = File.join(RSpec.root, "support/assets/stub-300x200.png")
    @large_image_path = File.join(RSpec.root, "support/assets/stub-2048x100.png")
    @resource_id = "abc/123"
  end

  after do
    FileUtils.rm_rf(@local_root)
  end

  context "without security tokens" do
    def app
      app = Proc.new do |env|
        [200, {}, ""]
      end
      SnapImage::Middleware.new(
        app,
        path: "/snapimage_api",
        config: {
          "primary_storage_server" => "local",
          "storage_servers" => [
            {
              "name" => "local",
              "type" => "LOCAL",
              "local_root" => File.join(RSpec.root, "storage"),
              "public_url" => "//example.com/images"
            }
          ]
        }
      )
    end

    before do
      # Store the image.
      json = { action: "generate_image", resource_identifier: @resource_id }.to_json
      post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@image_path, "image/png"), "json" => json

      json = {
        action: "generate_image",
        url: "http:#{JSON.parse(last_response.body)["image_url"]}",
        resource_identifier: @resource_id,
        crop_x: 10,
        crop_y: 50,
        crop_width: 40,
        crop_height: 60,
        width: 400,
        height: 600,
        sharpen: true
      }.to_json
      post "/snapimage_api", "json" => json
    end

    it "modifies successfully" do
      last_response.should be_successful
      last_response["Content-Type"].should eq "text/json"
      json = JSON.parse(last_response.body)
      json["status_code"].should eq 200
      json["message"].should eq "Get Modified Image Successful"
      json["image_url"].should match Regexp.new("^//example.com/images/abc/123/[a-z0-9]{8}-300x200-10x50x40x60-400x600-1.png$")
      json["image_width"].should eq 400
      json["image_height"].should eq 600
    end

    it "stores the image" do
      json = JSON.parse(last_response.body)
      path = File.join(@local_root, @resource_id, File.basename(json["image_url"]))
      File.exist?(path).should be_true
    end
  end

  context "with security tokens" do
    def app
      app = Proc.new do |env|
        [200, {}, ""]
      end
      SnapImage::Middleware.new(
        app,
        path: "/snapimage_api",
        config: {
          "security_salt" => "123456789",
          "primary_storage_server" => "local",
          "storage_servers" => [
            {
              "name" => "local",
              "type" => "LOCAL",
              "local_root" => File.join(RSpec.root, "storage"),
              "public_url" => "//example.com/images"
            }
          ]
        }
      )
    end

    before do
      @security_token = Digest::SHA1.hexdigest("client:#{Time.now.strftime("%Y-%m-%d")}:123456789:#{@resource_id}")

      # Store the image.
      json = {
        action: "generate_image",
        resource_identifier: @resource_id,
        client_security_token: @security_token
      }.to_json
      post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@image_path, "image/png"), "json" => json

      @options = {
        action: "generate_image",
        url: "http:#{JSON.parse(last_response.body)["image_url"]}",
        resource_identifier: @resource_id,
        crop_x: 10,
        crop_y: 50,
        crop_width: 40,
        crop_height: 60,
        width: 400,
        height: 600,
        sharpen: true
      }
    end

    it "requires authorization when no security token is provided" do
      request_json = @options.to_json
      post "/snapimage_api", "json" => request_json
      last_response.should be_successful
      last_response["content-type"].should eq "text/json"
      json = JSON.parse(last_response.body)
      json["status_code"].should eq 401
      json["message"].should eq "Authorization Required"
    end

    it "fails authorization when the security token is invalid" do
      request_json = @options.merge!({"client_security_token" => "abc"}).to_json
      post "/snapimage_api", "json" => request_json
      last_response.should be_successful
      last_response["content-type"].should eq "text/json"
      json = JSON.parse(last_response.body)
      json["status_code"].should eq 402
      json["message"].should eq "Authorization Failed"
    end

    it "modifies successfully" do
      request_json = @options.merge!({"client_security_token" => @security_token}).to_json
      post "/snapimage_api", "json" => request_json
      last_response.should be_successful
      last_response["Content-Type"].should eq "text/json"
      json = JSON.parse(last_response.body)
      json["status_code"].should eq 200
      json["message"].should eq "Get Modified Image Successful"
      json["image_url"].should match Regexp.new("^//example.com/images/abc/123/[a-z0-9]{8}-300x200-10x50x40x60-400x600-1.png$")
      json["image_width"].should eq 400
      json["image_height"].should eq 600
    end

    it "stores the image" do
      json = JSON.parse(last_response.body)
      path = File.join(@local_root, @resource_id, File.basename(json["image_url"]))
      File.exist?(path).should be_true
    end
  end
end
