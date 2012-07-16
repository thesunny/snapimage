require "spec_helper"

describe SnapImage::RequestFile do
  describe "#type" do
    it "returns the correct type" do
      file = SnapImage::RequestFile.new({type: "image/png"})
      file.type.should eq "png"
    end

    it "returns jpg when the type is jpeg" do
      file = SnapImage::RequestFile.new({type: "image/jpeg"})
      file.type.should eq "jpg"
    end
  end
end
