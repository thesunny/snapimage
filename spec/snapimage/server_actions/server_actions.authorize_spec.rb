#require "spec_helper"

#describe SnapImage::ServerActions::Authorize do
  #before do
    #class TestServerActions
      #include SnapImage::ServerActions::Authorize

      #attr_accessor :config

      #def initialize(request)
        #@request = request
        #@config = {"security_salt" => "abc123"}
      #end
    #end

    #@request = double("request")
    #@actions = TestServerActions.new(@request)
  #end

  #describe "#token_available?" do
    #before do
      #@request.stub(:json).and_return({"client_security_token" => "abc123"})
    #end
    #it "returns true when role's token is set" do
      #@actions.token_available?(:client).should be_true
    #end

    #it "returns false when role's token is not set" do
      #@actions.token_available?(:server).should be_false
    #end
  #end

  #describe "#generate_tokens" do
    #before do
      #@request.stub(:json).and_return({"resource_identifier" => "123"})
    #end

    #it "generates three token" do
      #now = Time.now
      #yesterday = (now - 24*60*60).strftime("%Y-%m-%d")
      #today = now.strftime("%Y-%m-%d")
      #tomorrow = (now + 24*60*60).strftime("%Y-%m-%d")
      #yesterday_token = Digest::SHA1.hexdigest("client:#{yesterday}:abc123:123")
      #today_token = Digest::SHA1.hexdigest("client:#{today}:abc123:123")
      #tomorrow_token = Digest::SHA1.hexdigest("client:#{tomorrow}:abc123:123")
      #@actions.generate_tokens(:client).should eq [yesterday_token, today_token, tomorrow_token]
    #end
  #end

  #describe "#authorize" do
    #it "returns true when the security_salt is not set" do
      #@actions.config = {}
      #@actions.authorize(:client).should be_true
    #end

    #it "raises an error when the token is not available" do
      #@actions.stub(:token_available?).and_return(false)
      #expect { @actions.authorize(:client) }.should raise_error SnapImage::AuthorizationRequired
    #end

    #it "raises an error when the token does not match" do
      #@request.stub(:json).and_return({"client_security_token" => "abc123", "resource_identifier" => "123"})
      #@actions.stub(:token_available?).and_return(true)
      #expect { @actions.authorize(:client) }.should raise_error SnapImage::AuthorizationFailed
    #end
  #end
#end
