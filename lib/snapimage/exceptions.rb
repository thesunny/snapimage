module SnapImage
  # Configuration.
  class InvalidConfig < StandardError; end
  class InvalidStorageConfig < StandardError; end
  class UnknownConfigType < StandardError; end

  # Authorization.
  class AuthorizationRequired < StandardError; end
  class AuthorizationFailed < StandardError; end

  # Request.
  class BadRequest < StandardError; end
  class ActionNotImplemented < StandardError; end

  # Files.
  class UnknownFileType < StandardError; end
  class FileDoesNotExist < StandardError; end

  # Images.
  class InvalidImageIdentifier < StandardError; end

  # Resources.
  class InvalidResourceIdentifier < StandardError; end
end
