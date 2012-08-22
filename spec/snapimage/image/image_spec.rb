require "spec_helper"

describe SnapImage::Image do
  before do
    @image_path = File.join(RSpec.root, "support/assets/stub-300x200.png")
  end

  describe "#crop" do
    before do
      @image = SnapImage::Image.new
      @image.set_image_from_path(@image_path)
    end

    it "correctly crops image" do
      @image.crop(10, 30, 20, 30)
      @image.width.should eq 20
      @image.height.should eq 30
    end
  end

  describe "#resize" do
    before do
      @image = SnapImage::Image.new
      @image.set_image_from_path(@image_path)
    end

    it "raises an error when no height is specified and maintaining aspect ratio is false" do
      expect { @image.resize(100, nil, false) }.should raise_error
    end

    it "resizes the image when the width is larger or equal to the height" do
      @image.resize(330)
      @image.width.should eq 330
      @image.height.should eq 220
    end

    it "resizes the image when the width is less than the height" do
      @image.resize(150)
      @image.width.should eq 150
      @image.height.should eq 100
    end

    it "resizes the image to fit within the width/height while maintaining aspect ratio" do
      @image.resize(150, 200)
      @image.width.should eq 150
      @image.height.should eq 100
    end

    it "stretches image when not maintaining aspect ratio" do
      @image.resize(100, 200, false)
      @image.width.should eq 100
      @image.height.should eq 200
    end
  end
end
