require "spec_helper"

describe SnapImage::Middleware do
  before do
    @env = { "PATH_INFO" => "/test"}
    @app = double("app")
  end

  describe "#call" do
    it "passes the call through to the rack app when the path does not match" do
      @app.should_receive(:call).with(@env).and_return("app")
      SnapImage::Storage.stub(:new)
      middleware = SnapImage::Middleware.new(@app, config: {})
      middleware.call(@env).should eq "app"
    end

    it "passes the call through to the SnapImage Server" do
      server = double("server")
      server.should_receive(:call).and_return("server")
      SnapImage::Storage.stub(:new)
      SnapImage::Server.stub(:new).and_return(server)

      @app.should_not_receive(:call)

      middleware = SnapImage::Middleware.new(@app, config: {}, path: "/test")
      middleware.call(@env).should eq "server"
    end
  end
end
