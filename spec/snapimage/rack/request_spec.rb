require "spec_helper"

describe SnapImage::Request do
  before do
    @request = SnapImage::Request.new({})
  end

  describe "#bad_request?" do
    it "returns true if the request is not a post" do
      json = { action: "test", resource_identifier: "123" }.to_json
      @request.stub(:post?).and_return(false)
      @request.stub(:POST).and_return({"json" => json})
      @request.bad_request?.should be_true
    end

    it "returns true if the request does not include json" do
      @request.stub(:post?).and_return(true)
      @request.stub(:POST).and_return({})
      @request.bad_request?.should be_true
    end

    it "returns true if the request does not include an action" do
      json = { resource_identifier: "123" }.to_json
      @request.stub(:post?).and_return(true)
      @request.stub(:POST).and_return({"json" => json})
      @request.bad_request?.should be_true
    end

    it "returns true if the request does not include a resource_identifier" do
      json = { action: "test" }.to_json
      @request.stub(:post?).and_return(true)
      @request.stub(:POST).and_return({"json" => json})
      @request.bad_request?.should be_true
    end

    it "returns false if the request is valid" do
      json = { action: "test", resource_identifier: "123" }.to_json
      @request.stub(:post?).and_return(true)
      @request.stub(:POST).and_return({"json" => json})
      @request.bad_request?.should be_false
    end
  end

  describe "#json" do
    it "returns the json object" do
      @request.stub(:bad_request?).and_return(false)
      @request.stub(:POST).and_return({"json" => '{"data":"value"}'})
      json = @request.json
      json["data"].should eq "value"
    end
  end
end
