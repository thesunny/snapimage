require "spec_helper"

describe SnapImage::Server do
  before do
    @request = double("request")
    @config = double("config")
    @config.stub(:storage).and_return("storage")
    @server = SnapImage::Server.new(@request, @config)
  end

  describe "#call" do
    it "returns a bad request when the request is bad" do
      @request.stub(:bad_request?).and_return(true)
      response = @server.call
      response[0].should eq 200
      response[1]["Content-Type"].should eq "text/json"
      response[2].body.should eq ['{"status_code":400,"message":"Bad Request"}']
    end

    it "returns invalid resource identifier when the resource identifier is invalid" do
      @request.stub(:bad_request?).and_return(false)
      @request.stub(:json).and_return({"resource_identifier" => "abc?123"})
      response = @server.call
      response[0].should eq 200
      response[1]["Content-Type"].should eq "text/json"
      response[2].body.should eq ['{"status_code":404,"message":"Invalid Resource Identifier"}']
    end

    it "returns not implemented when the action does not exist" do
      @request.stub(:bad_request?).and_return(false)
      @request.stub(:json).and_return({"action" => "test", "resource_identifier" => "abc/123"})
      response = @server.call
      response[0].should eq 200
      response[1]["Content-Type"].should eq "text/json"
      response[2].body.should eq ['{"status_code":501,"message":"Not Implemented"}']
    end

    it "calls the action" do
      response = double("response")
      response.stub(:finish)
      generate_image = double("Generate Image")
      generate_image.should_receive(:call).once.and_return(response)
      SnapImage::ServerActions::GenerateImage.stub(:new).and_return(generate_image)
      @request.stub(:bad_request?).and_return(false)
      @request.stub(:json).and_return({"action" => "generate_image", "resource_identifier" => "abc/123"})
      @server.call
    end
  end

  describe "#get_action_class" do
    it "returns the correct class" do
      @server.send(:get_action_class, "generate_image").should be SnapImage::ServerActions::GenerateImage
    end
  end
end
