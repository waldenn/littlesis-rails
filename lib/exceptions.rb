module Exceptions
  class PermissionError < StandardError; end
  class NotFoundError < StandardError; end
  class MissingApiTokenError < StandardError; end
  class RestrictedUserError < StandardError; end
  class CannotRestoreError < StandardError
    def message
      "Cannot restore a model that has not yet been deleted"
    end
  end

  class MissingEntityAssociationDataError < StandardError
    def message
      "Missing association data for this Entity"
    end
  end
end
