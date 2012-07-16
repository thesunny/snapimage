require "spec_helper"
require "rack/test"

describe "Upload" do
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

    context "upload a file" do
      before do
        json = {
          action: "generate_image",
          resource_identifier: @resource_id,
          response_content_type: "text/html",
          response_template: "json = {{json}}"
        }.to_json
        post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@image_path, "image/png"), "json" => json
      end

      it "is successful" do
        last_response.should be_successful
        last_response["Content-Type"].should eq "text/html"
        matches = last_response.body.match(/json = ({.*})/)
        matches.should_not be_nil
        matches.size.should eq 2
        json = JSON.parse(matches[1])
        json["status_code"].should eq 200
        json["message"].should eq "Get Modified Image Successful"
        json["image_url"].should match Regexp.new("^//example.com/images/abc/123/[a-z0-9]{8}-300x200.png$")
        json["image_width"].should eq 300
        json["image_height"].should eq 200
      end

      it "stores the image" do
        matches = last_response.body.match(/json = ({.*})/)
        json = JSON.parse(matches[1])
        path = File.join(@local_root, @resource_id, File.basename(json["image_url"]))
        File.exist?(path).should be_true
      end
    end

    context "upload from URL" do
      before do
        json = {
          action: "generate_image",
          url: "http://snapeditor.com/assets/se_logo.png",
          resource_identifier: @resource_id
        }.to_json
        post "/snapimage_api", "json" => json
      end

      it "is successful" do
        last_response.should be_successful
        last_response["Content-Type"].should eq "text/json"
        json = JSON.parse(last_response.body)
        json["status_code"].should eq 200
        json["message"].should eq "Get Modified Image Successful"
        json["image_url"].should match Regexp.new("^//example.com/images/abc/123/[a-z0-9]{8}-54x41.png$")
        json["image_width"].should eq 54
        json["image_height"].should eq 41
      end

      it "stores the image" do
        json = JSON.parse(last_response.body)
        path = File.join(@local_root, @resource_id, File.basename(json["image_url"]))
        File.exist?(path).should be_true
      end
    end

    context "upload too large" do
      before do
        json = { action: "generate_image", resource_identifier: @resource_id }.to_json
        post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@large_image_path, "image/png"), "json" => json
      end

      it "resizes successfully" do
        last_response.should be_successful
        last_response["Content-Type"].should eq "text/json"
        json = JSON.parse(last_response.body)
        json["status_code"].should eq 200
        json["message"].should eq "Get Modified Image Successful"
        json["image_url"].should match Regexp.new("^//example.com/images/abc/123/[a-z0-9]{8}-1024x50.png$")
        json["image_width"].should eq 1024
        json["image_height"].should eq 50
      end

      it "stores the image" do
        json = JSON.parse(last_response.body)
        path = File.join(@local_root, @resource_id, File.basename(json["image_url"]))
        File.exist?(path).should be_true
      end
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
    end

    context "upload a file" do
      before do
        @options = { action: "generate_image", resource_identifier: @resource_id }
      end

      it "requires authorization when no security token is provided" do
        request_json = @options.to_json
        post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@image_path, "image/png"), "json" => request_json
        last_response.should be_successful
        last_response["content-type"].should eq "text/json"
        json = JSON.parse(last_response.body)
        json["status_code"].should eq 401
        json["message"].should eq "Authorization Required"
      end

      it "fails authorization when the security token is invalid" do
        request_json = @options.merge!({"client_security_token" => "abc"}).to_json
        post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@image_path, "image/png"), "json" => request_json
        last_response.should be_successful
        last_response["content-type"].should eq "text/json"
        json = JSON.parse(last_response.body)
        json["status_code"].should eq 402
        json["message"].should eq "Authorization Failed"
      end

      it "is successful when the security token is valid" do
        request_json = @options.merge!({"client_security_token" => @security_token}).to_json
        post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@image_path, "image/png"), "json" => request_json
        last_response.should be_successful
        last_response["content-type"].should eq "text/json"
        json = JSON.parse(last_response.body)
        json["status_code"].should eq 200
        json["message"].should eq "Get Modified Image Successful"
        json["image_url"].should match Regexp.new("^//example.com/images/abc/123/[a-z0-9]{8}-300x200.png$")
        json["image_width"].should eq 300
        json["image_height"].should eq 200
      end
    end

    context "upload from URL" do
      before do
        @options = {
          action: "generate_image",
          url: "http://snapeditor.com/assets/se_logo.png",
          resource_identifier: @resource_id
        }
      end

      it "requires authorization when no security token is provided" do
        request_json = @options.to_json
        post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@image_path, "image/png"), "json" => request_json
        last_response.should be_successful
        last_response["content-type"].should eq "text/json"
        json = JSON.parse(last_response.body)
        json["status_code"].should eq 401
        json["message"].should eq "Authorization Required"
      end

      it "fails authorization when the security token is invalid" do
        request_json = @options.merge!({"client_security_token" => "abc"}).to_json
        post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@image_path, "image/png"), "json" => request_json
        last_response.should be_successful
        last_response["content-type"].should eq "text/json"
        json = JSON.parse(last_response.body)
        json["status_code"].should eq 402
        json["message"].should eq "Authorization Failed"
      end

      it "is successful" do
        request_json = @options.merge!({"client_security_token" => @security_token}).to_json
        post "/snapimage_api", "json" => request_json
        last_response.should be_successful
        last_response["Content-Type"].should eq "text/json"
        json = JSON.parse(last_response.body)
        json["status_code"].should eq 200
        json["message"].should eq "Get Modified Image Successful"
        json["image_url"].should match Regexp.new("^//example.com/images/abc/123/[a-z0-9]{8}-54x41.png$")
        json["image_width"].should eq 54
        json["image_height"].should eq 41
      end
    end
  end
end
