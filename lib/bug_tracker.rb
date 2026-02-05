# frozen_string_literal: true

require_relative "bug_tracker/version"
require_relative "bug_tracker/configuration"
require_relative "bug_tracker/adapters/base"
require_relative "bug_tracker/adapters/null"
require_relative "bug_tracker/adapters/sentry"
require_relative "bug_tracker/context_manager"
require_relative "bug_tracker/base_error"

# Load Railtie if Rails is present
require_relative "bug_tracker/railtie" if defined?(Rails::Railtie)

module BugTracker
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def notify(exception, **context)
      context_manager.notify(exception, **context)
    end

    def extra_context(**context)
      context_manager.extra_context(**context)
    end

    def user_context(hash = {})
      context_manager.user_context(hash)
    end

    def last_event_id(error = nil)
      context_manager.last_event_id(error)
    end

    private

    def context_manager
      @context_manager ||= ContextManager.new(adapter, configuration)
    end

    def adapter
      @adapter ||= build_adapter
    end

    def build_adapter
      adapter_config = configuration.adapter

      case adapter_config
      when :sentry
        # Only use Sentry adapter if sentry-ruby is available
        if defined?(::Sentry)
          Adapters::Sentry.new(configuration)
        else
          Adapters::Null.new(configuration)
        end
      when :null
        Adapters::Null.new(configuration)
      when Adapters::Base
        adapter_config
      else
        raise ArgumentError, "Unknown adapter: #{adapter_config}"
      end
    end
  end
end
