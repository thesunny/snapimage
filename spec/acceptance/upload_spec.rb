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
        config: { "directory" => File.join(RSpec.root, "storage"), "public_url" => "http://snapimage.com/public", "max_file_size" => 600 }
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
        path = File.join(@local_root, @directory, File.basename(@image_path))
        File.exist?(path).should be_true
      end
    end

    context "upload duplicate files" do
      before do
        @times = 12
        @times.times do
          post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@image_path, "image/png"), "directory" => @directory
        end
      end

      it "is successful" do
        last_response.should be_successful
        last_response["Content-Type"].should eq "text/json"
        json = JSON.parse(last_response.body)
        json["status_code"].should eq 200
        json["message"].should eq "Success"
      end

      it "stores the images" do
        ext = File.extname(@image_path)
        basename = File.basename(@image_path, ext)
        (1..@times - 1).each do |i|
          path = File.join(@local_root, @directory, "#{basename}(#{i})#{ext}")
          File.exist?(path).should be_true
        end
      end
    end

    context "upload too large" do
      before do
        post "/snapimage_api", "file" => Rack::Test::UploadedFile.new(@large_image_path, "image/png"), "directory" => @directory
      end

      it "fails" do
        last_response.should be_successful
        last_response["Content-Type"].should eq "text/json"
        json = JSON.parse(last_response.body)
        json["status_code"].should eq 405
        json["message"].should eq "File Too Large"
      end

      it "does not store the image" do
        path = File.join(@local_root, @directory, File.basename(@image_path))
        File.exist?(path).should be_false
      end
    end
  end
end
