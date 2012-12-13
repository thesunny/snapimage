module SnapImage
  # Configuration.
  class InvalidConfig < StandardError; end
  class UnknownConfigType < StandardError; end
  class MissingConfig < StandardError; end

  # Authorization.
  #class AuthorizationRequired < StandardError; end
  #class AuthorizationFailed < StandardError; end

  # Request.
  class BadRequest < StandardError; end
  #class ActionNotImplemented < StandardError; end
  class InvalidFilename < StandardError; end
  class InvalidDirectory < StandardError; end
  class FileTooLarge < StandardError; end

  # Files.
  class UnknownFileType < StandardError; end
  #class FileDoesNotExist < StandardError; end

end
