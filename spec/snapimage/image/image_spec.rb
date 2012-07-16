require "spec_helper"

describe SnapImage::Image do
  before do
    @image_path = File.join(RSpec.root, "support/assets/stub-300x200.png")
  end

  describe "#crop" do
    before do
      @image = SnapImage::Image.new
      @image.set_image_from_path(@image_path)
      @original_width = @image.width
      @original_height = @image.height
    end

    it "returns the correctly cropped image" do
      image = @image.crop(10, 30, 20, 30)
      image.width.should eq 20
      image.height.should eq 30
    end

    it "does not modify the original image" do
      image = @image.crop(10, 30, 20, 30)
      @image.width.should eq @original_width
      @image.height.should eq @original_height
    end
  end

  describe "#resize" do
    before do
      @image = SnapImage::Image.new
      @image.set_image_from_path(@image_path)
      @original_width = @image.width
      @original_height = @image.height
    end

    it "raises an error when no height is specified and maintaining aspect ratio is false" do
      expect { @image.resize(100, nil, false) }.should raise_error
    end

    it "returns an appropriately resized image when the width is larger or equal to the height" do
      image = @image.resize(330)
      image.width.should eq 330
      image.height.should eq 220
    end

    it "returns an appropriately resized image when the width is less than the height" do
      image = @image.resize(150)
      image.width.should eq 150
      image.height.should eq 100
    end

    it "returns an image that fits within the width/height while maintaining aspect ratio" do
      image = @image.resize(150, 200)
      image.width.should eq 150
      image.height.should eq 100
    end

    it "returns a stretched image when not maintaining aspect ratio" do
      image = @image.resize(100, 200, false)
      image.width.should eq 100
      image.height.should eq 200
    end

    it "does not modify the original image" do
      image = @image.resize(100)
      @image.width.should eq @original_width
      @image.height.should eq @original_height
    end
  end
end
