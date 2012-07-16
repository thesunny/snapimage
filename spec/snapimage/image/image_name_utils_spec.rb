require "spec_helper"

describe SnapImage::ImageNameUtils do
  before do
    @image_path = File.join(RSpec.root, "support/assets/stub.png")
  end

  describe "#get_image_type" do
    it "returns the correct type" do
      SnapImage::ImageNameUtils.get_image_type("http://example.com/storage/abc/123/image.png").should eq "png"
    end

    it "returns jpg when the type is jpeg" do
      SnapImage::ImageNameUtils.get_image_type("http://example.com/storage/abc/123/image.jpeg").should eq "jpg"
    end
  end

  describe "#get_image_name_parts" do
    it "raises an error when the image identifier is invalid" do
      expect { SnapImage::ImageNameUtils.get_image_name_parts("a bad url") }.should raise_error SnapImage::InvalidImageIdentifier
    end

    it "returns all the parts given a base image url" do
      url = "http://example.com/dkej2o3i-1024x768.png"
      parts = SnapImage::ImageNameUtils.get_image_name_parts(url)
      parts[:is_base].should be_true
      parts[:full].should eq url
      parts[:path].should eq "http://example.com"
      parts[:filename].should eq "dkej2o3i-1024x768.png"
      parts[:basename].should eq "dkej2o3i"
      parts[:original_dimensions].should eq [1024, 768]
      parts[:extname].should eq "png"
      parts[:crop].should be_nil
      parts[:dimensions].should be_nil
      parts[:sharpen].should be_nil
    end

    it "returns all the parts given a modified image url" do
      url = "http://example.com/dkej2o3i-1024x768-6x10x143x402-640x480-1.png"
      parts = SnapImage::ImageNameUtils.get_image_name_parts(url)
      parts[:is_base].should be_false
      parts[:full].should eq url
      parts[:path].should eq "http://example.com"
      parts[:filename].should eq "dkej2o3i-1024x768-6x10x143x402-640x480-1.png"
      parts[:basename].should eq "dkej2o3i"
      parts[:original_dimensions].should eq [1024, 768]
      parts[:crop][:x].should eq 6
      parts[:crop][:y].should eq 10
      parts[:crop][:width].should eq 143
      parts[:crop][:height].should eq 402
      parts[:dimensions].should eq [640, 480]
      parts[:sharpen].should eq true
      parts[:extname].should eq "png"
    end

    it "returns all the parts given a filename" do
      url = "dkej2o3i-1024x768-6x10x143x402-640x480-1.png"
      parts = SnapImage::ImageNameUtils.get_image_name_parts(url)
      parts[:is_base].should be_false
      parts[:full].should eq url
      parts[:path].should eq ""
      parts[:filename].should eq "dkej2o3i-1024x768-6x10x143x402-640x480-1.png"
      parts[:basename].should eq "dkej2o3i"
      parts[:original_dimensions].should eq [1024, 768]
      parts[:crop][:x].should eq 6
      parts[:crop][:y].should eq 10
      parts[:crop][:width].should eq 143
      parts[:crop][:height].should eq 402
      parts[:dimensions].should eq [640, 480]
      parts[:sharpen].should eq true
      parts[:extname].should eq "png"
    end
  end

  describe "#get_base_image_path" do
    it "returns the base image name from the url" do
      url = "http://example.com/dkej2o3i-1024x768-6x10x143x402-640x480-1.png"
      SnapImage::ImageNameUtils.get_base_image_path(url).should eq "http://example.com/dkej2o3i-1024x768.png"
    end
  end

  describe "#get_resized_image_name" do
    it "returns the resized name given a base image" do
      name = SnapImage::ImageNameUtils.get_resized_image_name("12345678-2048x100.png", 1024, 50)
      name.should eq "12345678-1024x50.png"
    end

    it "returns the resized name given a modified image" do
      name = SnapImage::ImageNameUtils.get_resized_image_name("12345678-1x1-0x0x1x1-2048x100-0.png", 1024, 50)
      name.should eq "12345678-1x1-0x0x1x1-1024x50-0.png"
    end
  end

  describe "#generate_basename" do
    it "generates 8 random alphanumeric characters" do
      SnapImage::ImageNameUtils.generate_basename.should match /^[a-z0-9]{8}$/
    end
  end

  describe "#generate_image_name" do
    it "generates a base image name without options" do
      SnapImage::ImageNameUtils.generate_image_name(1024, 768, "png").should match /[a-z0-9]{8}-1024x768\.png/
    end

    it "generates a base image name with just a basename option" do
      SnapImage::ImageNameUtils.generate_image_name(1024, 768, "png", basename: "test").should eq "test-1024x768.png"
    end

    it "generates a modified image name with options" do
      SnapImage::ImageNameUtils.generate_image_name(
        1024,
        768,
        "png",
        basename: "image",
        crop: {
          x: 6,
          y: 7,
          width: 134,
          height: 350
        },
        width: 640,
        height: 480,
        sharpen: true
      ).should eq "image-1024x768-6x7x134x350-640x480-1.png"
    end
  end
end
