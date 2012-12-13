#require "spec_helper"

#describe SnapImage::ServerActions::GenerateImage do
  #before do
    #@image_path = File.join(RSpec.root, "support/assets/stub-300x200.png")
    #@storage = double("storage")
    #@config = { "max_width" => 1024, "max_height" => 2048 }
    #@config.stub(:storage).and_return(@storage)
    #@request = double("request")
    #@response = double("response")
    #@generate_image = SnapImage::ServerActions::GenerateImage.new(@config, @request, @response)
  #end

  #describe "#source_image_defined?" do
    #it "returns false if file and url are not defined" do
      #@request.stub(:file).and_return(nil)
      #@request.stub(:json).and_return({})
      #@generate_image.send(:source_image_defined?).should be_false
    #end

    #it "returns true when file is defined" do
      #@request.stub(:file).and_return("file")
      #@request.stub(:json).and_return({})
      #@generate_image.send(:source_image_defined?).should be_true
    #end

    #it "returns true when url is defined" do
      #@request.stub(:file).and_return(nil)
      #@request.stub(:json).and_return({"url" => "something"})
      #@generate_image.send(:source_image_defined?).should be_true
    #end
  #end

  #describe "#get_max_width?" do
    #it "returns the server max width when JSON 'max_width' is not defined" do
      #@request.stub(:json).and_return({})
      #@generate_image.send(:get_max_width).should eq 1024
    #end

    #it "returns the server max width when JSON 'max_width' is larger" do
      #@request.stub(:json).and_return({"max_width" => "4096"})
      #@generate_image.send(:get_max_width).should eq 1024
    #end

    #it "returns the JSON 'max_width' when server max width is larger" do
      #@request.stub(:json).and_return({"max_width" => "640"})
      #@generate_image.send(:get_max_width).should eq 640
    #end
  #end

  #describe "#get_max_height?" do
    #it "returns the server max height when JSON 'max_height' is not defined" do
      #@request.stub(:json).and_return({})
      #@generate_image.send(:get_max_height).should eq 2048
    #end

    #it "returns the server max height when JSON 'max_height' is larger" do
      #@request.stub(:json).and_return({"max_height" => "4096"})
      #@generate_image.send(:get_max_height).should eq 2048
    #end

    #it "returns the JSON 'max_height' when server max height is larger" do
      #@request.stub(:json).and_return({"max_height" => "640"})
      #@generate_image.send(:get_max_height).should eq 640
    #end
  #end

  #describe "#get_image_for_modification" do
    #context "upload" do
      #before do
        #@generate_image.stub(:upload?).and_return(true)
      #end

      #it "uploads the image and returns it when a file is specified" do
        #@request.stub(:file).and_return("file")
        #@request.stub(:json).and_return({"resource_identifier" => "abc123"})
        #@storage.should_receive(:add_upload).with("file", "abc123").once.and_return("image")
        #@generate_image.send(:get_image_for_modification).should eq "image"
      #end

      #it "downloads the image and returns it when a local url is specified" do
        #@request.stub(:file).and_return(nil)
        #@request.stub(:json).and_return({"url" => "http://example.com/12345678-1024x768.png", "resource_identifier" => "abc123"})
        #@storage.should_receive(:add_url).with("http://example.com/12345678-1024x768.png", "abc123").once.and_return("image")
        #@generate_image.send(:get_image_for_modification).should eq "image"
      #end
    #end

    #context "modify" do
      #before do
        #@generate_image.stub(:upload?).and_return(false)
      #end

      #it "gets the base image" do
        #@request.stub(:json).and_return("url" => "http://example.com/fi3k2od0-1027x768-1x2x640x480-300x200-1.png")
        #@storage.should_receive(:get).with("http://example.com/fi3k2od0-1027x768.png").once.and_return("image")
        #@generate_image.send(:get_image_for_modification).should eq "image"
      #end
    #end
  #end

  #describe "#modify_image" do
    #before do
      #@image = SnapImage::Image.from_path(@image_path, "http://example.com/12345678-300x200.png")
    #end

    #it "does nothing when there are no modifications" do
      #@request.stub(:json).and_return({})
      #result = @generate_image.send(:modify_image, @image)
      #result[:image].should be @image
      #result[:name].should eq "12345678-300x200.png"
    #end

    #it "crops" do
      #@request.stub(:json).and_return({"crop_x" => 10, "crop_y" => 20, "crop_width" => 50, "crop_height" => 100})
      #result = @generate_image.send(:modify_image, @image)
      #result[:image].width.should eq 50
      #result[:image].height.should eq 100
      #result[:name].should eq "12345678-300x200-10x20x50x100-50x100-0.png"
    #end

    #it "resizes" do
      #@request.stub(:json).and_return({"width" => 400, "height" => 50})
      #result = @generate_image.send(:modify_image, @image)
      #result[:image].width.should eq 400
      #result[:image].height.should eq 50
      #result[:name].should eq "12345678-300x200-0x0x300x200-400x50-0.png"
    #end

    #it "resizes to fit" do
      #@request.stub(:json).and_return({"width" => 2048, "height" => 100})
      #result = @generate_image.send(:modify_image, @image)
      #result[:image].width.should eq 1024
      #result[:image].height.should eq 50
      #result[:name].should eq "12345678-300x200-0x0x300x200-1024x50-0.png"
    #end

    #it "sharpens" do
      #@request.stub(:json).and_return({"sharpen" => true})
      #result = @generate_image.send(:modify_image, @image)
      #result[:image].width.should eq 300
      #result[:image].height.should eq 200
      #result[:name].should eq "12345678-300x200-0x0x300x200-300x200-1.png"
    #end
  #end
#end
