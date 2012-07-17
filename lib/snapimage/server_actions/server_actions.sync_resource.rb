module SnapImage
  module ServerActions
    class SyncResource
      include SnapImage::ServerActions::Authorize

      def initialize(config, request, response)
        @config = config
        @storage = config.storage
        @request = request
        @response = response
      end

      def call
        authorize(:server)
        if request_valid?
          @response.set_success(
            message: "Image Sync Successful",
            deleted_image_urls: sync
          )
        else
          @response.set_bad_request
        end
        @response
      end

      private

      # Returns true if the request is valid. False otherwise.
      def request_valid?
        !!(content_valid? && @request.json["sync_date_time"])
      end

      # Returns true if "content" in the request is valid. False otherwise.
      def content_valid?
        content = @request.json["content"]
        !!(content && content.is_a?(Hash) && !content.empty?)
      end

      # Concatenates all the content and returns it.
      def get_content
        @request.json["content"].values.inject("") { |result, element| result + element }
      end

      def urls_to_keep
        content = get_content
        keep = {}
        @storage.url_regexps.each do |regexp|
          # We use #scan instead of #match because #match returns only the
          # first match. #scan will return all matches that don't overlap.
          # However, #scan does not behave like #match. If the regexp contains
          # groupings, #scan returns only the matched groups. Otherwise, it
          # returns the entire match.
          # To normalize, we take the given regexp and always wrap it in a
          # group to ensure that the regexp always has a group and we always
          # get back the entire match.
          content.scan(Regexp.new("(#{regexp.source})", regexp.options)).each do |match|
            keep[match[0]] = true
            # If the image is modified, make sure to keep the base image too.
            if !SnapImage::ImageNameUtils.base_image?(match[0])
              keep[SnapImage::ImageNameUtils.get_base_image_path(match[0])] = true
            end
          end
        end
        keep.keys
      end

      def sync
        urls_to_delete = @storage.get_resource_urls(
          @request.json["resource_identifier"],
          # DateTime only deals with years and days. We need to convert to a
          # Time first to handle seconds, then convert back to a DateTime.
          (DateTime.parse(@request.json["sync_date_time"]).to_time - 3).to_datetime
        ) - urls_to_keep
        urls_to_delete.each { |url| @storage.delete(url) }
      end
    end
  end
end
