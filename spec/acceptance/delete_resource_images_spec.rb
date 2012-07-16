require "spec_helper"
require "rack/test"

describe "Delete Resource Images" do
  include Rack::Test::Methods

  before do
    @local_root = File.join(RSpec.root, "storage")
    @image_path = File.join(RSpec.root, "support/assets/stub-300x200.png")
    @resource_id_1 = "abc/123"
    @resource_id_2 = "abc/456"
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
      # Store some images.
      json = { action: "generate_image", resource_identifier: @resource_id_1 }.to_json
      post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@image_path, "image/png"), "json" => json
      @url_1 = JSON.parse(last_response.body)["image_url"]
      post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@image_path, "image/png"), "json" => json
      @url_2 = JSON.parse(last_response.body)["image_url"]

      json = { action: "generate_image", resource_identifier: @resource_id_2 }.to_json
      post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@image_path, "image/png"), "json" => json
      @url_3 = JSON.parse(last_response.body)["image_url"]
      post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@image_path, "image/png"), "json" => json
      @url_4 = JSON.parse(last_response.body)["image_url"]

      json = {
        action: "delete_resource_images",
        resource_identifier: @resource_id_1
      }.to_json
      post "/snapimage_api", "json" => json
    end

    it "is successful" do
      last_response.should be_successful
      last_response["Content-Type"].should eq "text/json"
      json = JSON.parse(last_response.body)
      json["status_code"].should eq 200
      json["message"].should eq "Delete Resource Images Successful"
      json["deleted_image_urls"].size.should eq 2
      json["deleted_image_urls"].include?(@url_1).should be_true
      json["deleted_image_urls"].include?(@url_2).should be_true
    end

    it "deletes the resource" do
      File.exists?(File.join(@local_root, @resource_id_1)).should be_false
    end

    it "does not delete other resources" do
      File.exists?(File.join(@local_root, @resource_id_2)).should be_true
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
      @client_security_token_1 = Digest::SHA1.hexdigest("client:#{Time.now.strftime("%Y-%m-%d")}:123456789:#{@resource_id_1}")
      @client_security_token_2 = Digest::SHA2.hexdigest("client:#{Time.now.strftime("%Y-%m-%d")}:223456789:#{@resource_id_2}")
      @server_security_token = Digest::SHA1.hexdigest("server:#{Time.now.strftime("%Y-%m-%d")}:123456789:#{@resource_id_1}")

      # Store some images.
      json = {
        action: "generate_image",
        resource_identifier: @resource_id_1,
        client_security_token: @client_security_token_1
      }.to_json
      post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@image_path, "image/png"), "json" => json
      @url_1 = JSON.parse(last_response.body)["image_url"]
      post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@image_path, "image/png"), "json" => json
      @url_2 = JSON.parse(last_response.body)["image_url"]

      json = {
        action: "generate_image",
        resource_identifier: @resource_id_2,
        client_security_token: @client_security_token_2
      }.to_json
      post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@image_path, "image/png"), "json" => json
      @url_3 = JSON.parse(last_response.body)["image_url"]
      post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@image_path, "image/png"), "json" => json
      @url_4 = JSON.parse(last_response.body)["image_url"]

      @options = { action: "delete_resource_images", resource_identifier: @resource_id_1 }
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

    it "deletes successfully" do
      request_json = @options.merge!({"server_security_token" => @server_security_token}).to_json
      post "/snapimage_api", "json" => request_json
      last_response.should be_successful
      last_response["Content-Type"].should eq "text/json"
      json = JSON.parse(last_response.body)
      json["status_code"].should eq 200
      json["message"].should eq "Delete Resource Images Successful"
      json["deleted_image_urls"].size.should eq 2
      json["deleted_image_urls"].include?(@url_1).should be_true
      json["deleted_image_urls"].include?(@url_2).should be_true
    end
  end
end
