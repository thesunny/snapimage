require "spec_helper"
require "rack/test"

describe "Sync" do
  include Rack::Test::Methods

  before do
    @local_root = File.join(RSpec.root, "storage")
    @image_path = File.join(RSpec.root, "support/assets/stub-300x200.png")
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
        "/snapimage_api",
        "primary_storage_server" => "local",
        "storage_servers" => [
          {
            "name" => "local",
            "type" => "LOCAL",
            "local_root" => File.join(RSpec.root, "storage"),
            "public_url" => "//example.com/images"
          }
        ]
      )
    end

    before do
      # Store some images.
      json = { action: "generate_image", resource_identifier: @resource_id }.to_json

      @before_1 = DateTime.now
      post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@image_path, "image/png"), "json" => json
      @url_1 = JSON.parse(last_response.body)["image_url"]

      @before_2 = DateTime.now
      post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@image_path, "image/png"), "json" => json
      @url_2 = "http:#{JSON.parse(last_response.body)["image_url"]}"

      @before_3 = DateTime.now
      post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@image_path, "image/png"), "json" => json
      @url_3 = "https:#{JSON.parse(last_response.body)["image_url"]}"

      sleep 1
      @before_4 = DateTime.now
      post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@image_path, "image/png"), "json" => json
      @url_4 = JSON.parse(last_response.body)["image_url"]
    end

    it "does nothing when all the images are in the content" do
      json = {
        action: "sync_resource",
        content: {
          body: "Some #{@url_1} and another '#{@url_2}'",
          footer: "This is #{@url_3} a footer"
        },
        sync_date_time: (DateTime.now + 3).iso8601,
        resource_identifier: @resource_id
      }.to_json
      post "/snapimage_api", "json" => json
      last_response.should be_successful
      last_response["Content-Type"].should eq "text/json"
      json = JSON.parse(last_response.body)
      json["status_code"].should eq 200
      json["message"].should eq "Image Sync Successful"
      json["deleted_image_urls"].size.should eq 0
    end

    it "deletes missing images" do
      # Add modified images.
      json = {
        action: "generate_image",
        url: "http:#{@url_1}",
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
      last_response.should be_successful
      json = JSON.parse(last_response.body)
      json["status_code"].should eq 200
      url_1_modified = json["image_url"]

      json = {
        action: "generate_image",
        url: @url_2,
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
      last_response.should be_successful
      json = JSON.parse(last_response.body)
      json["status_code"].should eq 200
      url_2_modified = json["image_url"]

      json = {
        action: "generate_image",
        url: @url_3,
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
      last_response.should be_successful
      json = JSON.parse(last_response.body)
      json["status_code"].should eq 200
      url_3_modified = json["image_url"]

      # Missing url_1_modified and url_1. (Should delete both)
      # Missing url_2_modified but url_2 is there. (Should delete modified only)
      # url_3_modified is there. (Should not delete either)
      # Missing url_4 which has not been modified (Should delete)
      json = {
        action: "sync_resource",
        content: {
          body: "Some #{@url_2} and another '#{url_3_modified}'"
        },
        sync_date_time: (DateTime.now + 4).iso8601,
        resource_identifier: @resource_id
      }.to_json
      post "/snapimage_api", "json" => json
      last_response.should be_successful
      last_response["Content-Type"].should eq "text/json"
      json = JSON.parse(last_response.body)
      json["status_code"].should eq 200
      json["message"].should eq "Image Sync Successful"
      json["deleted_image_urls"].size.should eq 4
      json["deleted_image_urls"].include?(@url_1).should be_true
      json["deleted_image_urls"].include?(url_1_modified).should be_true
      json["deleted_image_urls"].include?(url_2_modified).should be_true
      json["deleted_image_urls"].include?(@url_4).should be_true
    end

    it "does not delete missing images that are modified after the timestamp" do
      # Missing url_1 and url_4. (Deletes url_1 but not url_4)
      json = {
        action: "sync_resource",
        content: {
          body: "Some #{@url_2} and #{@url_3}"
        },
        sync_date_time: (@before_4 + 3).iso8601,
        resource_identifier: @resource_id
      }.to_json
      post "/snapimage_api", "json" => json
      last_response.should be_successful
      last_response["Content-Type"].should eq "text/json"
      json = JSON.parse(last_response.body)
      json["status_code"].should eq 200
      json["message"].should eq "Image Sync Successful"
      json["deleted_image_urls"].size.should eq 1
      json["deleted_image_urls"][0].should eq @url_1
    end
  end

  context "with security tokens" do
    def app
      app = Proc.new do |env|
        [200, {}, ""]
      end
      SnapImage::Middleware.new(
        app,
        "/snapimage_api",
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
      )
    end

    before do
      @client_security_token = Digest::SHA1.hexdigest("client:#{Time.now.strftime("%Y-%m-%d")}:123456789:#{@resource_id}")
      @server_security_token = Digest::SHA1.hexdigest("server:#{Time.now.strftime("%Y-%m-%d")}:123456789:#{@resource_id}")

      # Store some images.
      json = {
        action: "generate_image",
        resource_identifier: @resource_id,
        client_security_token: @client_security_token
      }.to_json

      post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@image_path, "image/png"), "json" => json
      @url_1 = JSON.parse(last_response.body)["image_url"]

      @options = {
        action: "sync_resource",
        content: {
          body: "Some #{@url_1}",
        },
        sync_date_time: (DateTime.now + 3).iso8601,
        resource_identifier: @resource_id
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
      request_json = @options.merge!({"server_security_token" => "abc"}).to_json
      post "/snapimage_api", "json" => request_json
      last_response.should be_successful
      last_response["content-type"].should eq "text/json"
      json = JSON.parse(last_response.body)
      json["status_code"].should eq 402
      json["message"].should eq "Authorization Failed"
    end

    it "syncs successfully" do
      json = @options.merge!({"server_security_token" => @server_security_token}).to_json
      post "/snapimage_api", "json" => json
      last_response.should be_successful
      last_response["Content-Type"].should eq "text/json"
      json = JSON.parse(last_response.body)
      json["status_code"].should eq 200
      json["message"].should eq "Image Sync Successful"
      json["deleted_image_urls"].size.should eq 0
    end
  end
end
