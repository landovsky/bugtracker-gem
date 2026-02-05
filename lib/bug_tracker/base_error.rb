# frozen_string_literal: true

module BugTracker
  class BaseError < StandardError
    ERROR_CODE = 500

    attr_reader :extra_context

    def initialize(message = nil, **context)
      super(message)
      @extra_context = context
    end

    def error_code
      self.class::ERROR_CODE
    end

    def as_json(options = {})
      result = {
        error: self.class.name.demodulize.underscore,
        error_code: error_code,
        message: message
      }

      # Merge extra_context into the JSON output
      result.merge!(extra_context) if extra_context.is_a?(Hash)

      # Optionally include backtrace
      result[:backtrace] = backtrace if options[:backtrace] && backtrace

      result
    end

    def to_json(options = {})
      as_json(options).to_json
    end
  end
end
