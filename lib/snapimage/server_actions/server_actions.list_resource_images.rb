module SnapImage
  module ServerActions
    class ListResourceImages
      include SnapImage::ServerActions::Authorize

      def initialize(config, request, response)
        @config = config
        @storage = config.storage
        @request = request
        @response = response
      end

      def call
        authorize(:server)
        @response.set_success(
          message: "List Resource Images Successful",
          image_urls: @storage.get_resource_urls(@request.json["resource_identifier"])
        )
        @response
      end
    end
  end
end
