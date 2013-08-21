require "spec_helper"

describe SnapImage::Request do
  before do
    @request = SnapImage::Request.new({})
  end

  describe "#bad_request?" do
    it "returns true if the request is not a post" do
      @request.stub(:post?).and_return(false)
      @request.stub(:POST).and_return({ "file" => "abc" })
      @request.bad_request?.should be_true
    end

    it "returns true if the request does not include file" do
      @request.stub(:post?).and_return(true)
      @request.stub(:POST).and_return({})
      @request.bad_request?.should be_true
    end

    it "returns false if the request is valid" do
      @request.stub(:post?).and_return(true)
      @request.stub(:POST).and_return({ "file" => "abc" })
      @request.bad_request?.should be_false
    end
  end
end
