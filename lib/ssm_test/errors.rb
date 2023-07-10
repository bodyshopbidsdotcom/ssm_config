# frozen_string_literal: true

module SsmTest
  # Generic PaperTrail exception.
  # @api public
  class Error < StandardError
  end

  # An unexpected option, perhaps a typo, was passed to a public API method.
  # @api public
  class InvalidBoolean < Error
  end

  # The application's database schema is not supported.
  # @api public
  class UnsupportedDatatype < Error
  end

  # The application's database column type is not supported.
  # @api public
end