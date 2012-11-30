require "spec_helper"
require "rack/test"

describe "Upload" do
  include Rack::Test::Methods

  before do
    @local_root = File.join(RSpec.root, "storage")
    @image_path = File.join(RSpec.root, "support/assets/stub-300x200.png")
    @large_image_path = File.join(RSpec.root, "support/assets/stub-2048x100.png")
    @directory = "abc/123"
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
        config: { "directory" => File.join(RSpec.root, "storage") }
      )
    end

    context "upload a file" do
      before do
        post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@image_path, "image/png"), "directory" => @directory
      end

      it "is successful" do
        last_response.should be_successful
        last_response["Content-Type"].should eq "text/json"
        json = JSON.parse(last_response.body)
        json["status_code"].should eq 200
        json["message"].should eq "Success"
      end

      it "stores the image" do
        json = JSON.parse(last_response.body)
        path = File.join(@local_root, @directory, File.basename(@image_path))
        File.exist?(path).should be_true
      end
    end

    #context "upload too large" do
      #before do
        #json = { action: "generate_image", resource_identifier: @resource_id }.to_json
        #post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@large_image_path, "image/png"), "json" => json
      #end

      #it "resizes successfully" do
        #last_response.should be_successful
        #last_response["Content-Type"].should eq "text/json"
        #json = JSON.parse(last_response.body)
        #json["status_code"].should eq 200
        #json["message"].should eq "Get Modified Image Successful"
        #json["image_url"].should match Regexp.new("^//example.com/images/abc/123/[a-z0-9]{8}-1024x50.png$")
        #json["image_width"].should eq 1024
        #json["image_height"].should eq 50
      #end

      #it "stores the image" do
        #json = JSON.parse(last_response.body)
        #path = File.join(@local_root, @resource_id, File.basename(json["image_url"]))
        #File.exist?(path).should be_true
      #end
    #end
  end
end
