module SsmConfig
  # Generic SsmConfig exception.
  class Error < StandardError
  end

  # An unexpected option, perhaps a typo, was passed to the value in the case of a boolean datatype
  class InvalidBoolean < Error
  end

  # The datatype entered is unsupported in SsmConfigRecord
  class UnsupportedDatatype < Error
  end
end
