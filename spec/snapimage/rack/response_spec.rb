require "spec_helper"

describe SnapImage::Response do
  before do
    @response = SnapImage::Response.new
  end

  describe "#set_success" do
    it "sets a default message" do
      @response.set_success
      @response.json[:message].should eq "Success"
    end

    it "merges in the info" do
      @response.set_success(some: "thing")
      @response.json[:some].should eq "thing"
    end
  end

  describe "#finish" do
    it "sets the body" do
      @response.json = { status_code: 200 }
      response = @response.finish
      response[2].body.should eq ['{"status_code":200}']
    end

    it "sets the Content-Type" do
      response = @response.finish
      response[1]["Content-Type"].should eq "text/json"
    end
  end

end
