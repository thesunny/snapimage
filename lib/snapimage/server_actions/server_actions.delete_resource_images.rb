module SnapImage
  module ServerActions
    class DeleteResourceImages
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
          message: "Delete Resource Images Successful",
          deleted_image_urls: @storage.delete_resource_images(@request.json["resource_identifier"])
        )
        @response
      end
    end
  end
end
