module SnapImage
  module ServerActions
    module Authorize
      def get_token(role)
        @request.json["#{role}_security_token"]
      end

      # Arguments:
      # * role:: Can be either :client or :server
      def token_available?(role)
        !!get_token(role)
      end

      # A string is generated using
      # * role:: "client" or "server"
      # * date:: Date in the format "YYYY-MM-DD"
      # * salt:: A shared salt
      # * resource_id:: The resource's identifier
      # and concatenated as "role:date:salt:resource_id".
      #
      # A SHA1 digest is generated off of the string to create a token.
      #
      # 3 tokens are generated: [yesterday, today, tomorrow].
      def generate_tokens(role)
        salt = @config["security_salt"]
        now = Time.now
        yesterday = (now - 24*60*60).strftime("%Y-%m-%d")
        today = now.strftime("%Y-%m-%d")
        tomorrow = (now + 24*60*60).strftime("%Y-%m-%d")
        resource_id = @request.json["resource_identifier"]
        [
          Digest::SHA1.hexdigest("#{role}:#{yesterday}:#{salt}:#{resource_id}"),
          Digest::SHA1.hexdigest("#{role}:#{today}:#{salt}:#{resource_id}"),
          Digest::SHA1.hexdigest("#{role}:#{tomorrow}:#{salt}:#{resource_id}")
        ]
      end

      # If "security_salt" is set in the config, authorization is performed.
      #
      # A string is generated using
      # * role:: "client" or "server"
      # * date:: Date in the format "YYYY-MM-DD"
      # * salt:: A shared salt
      # * resource_id:: The resource's identifier
      # and concatenated as "role:date:salt:resource_id".
      #
      # A SHA1 digest is generated off of the string to create a token. A token
      # for yesterday, today, and tomorrow are generated and used to compare
      # with the security token.
      #
      # When authorization fails, an error is raised. Authorization can fail in
      # 2 ways.
      # * AuthorizationRequired:: The role's security token is missing
      # * AuthorizationFailed:: The security token did not match the generated token
      #
      # If authorization is successful, true is returned.
      #
      # Arguments:
      # * role:: Can be either :client or :server
      def authorize(role)
        if @config["security_salt"]
          raise SnapImage::AuthorizationRequired unless token_available?(role)
          raise SnapImage::AuthorizationFailed unless generate_tokens(role).include?(get_token(role))
        end
        return true
      end
    end
  end
end
