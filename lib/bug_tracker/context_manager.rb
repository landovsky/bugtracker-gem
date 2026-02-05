# frozen_string_literal: true

module BugTracker
  class ContextManager
    def initialize(adapter, config)
      @adapter = adapter
      @config = config
    end

    def notify(exception, **context)
      # THE BUG FIX: Correctly extract extra_context from BaseError
      extra_context = if exception.respond_to?(:extra_context)
        exc_context = exception.extra_context
        exc_context.is_a?(Hash) ? exc_context : {}
      else
        {}
      end

      # Merge with any additional context passed to notify
      extra_context.merge!(context)

      # Log to console in development mode
      log_to_console(exception, extra_context) if config.development_mode

      # Send to adapter (Sentry, etc.)
      adapter.notify(exception, **extra_context)
    end

    def extra_context(**context)
      adapter.extra_context(**context)
    end

    def user_context(hash)
      adapter.user_context(hash)
    end

    def last_event_id(error = nil)
      adapter.last_event_id(error)
    end

    private

    attr_reader :adapter, :config

    def log_to_console(exception, extra_context)
      puts "\n" + "=" * 80
      puts "BugTracker: #{exception.class}: #{exception.message}"
      puts "=" * 80

      # Filter backtrace if configured
      backtrace = exception.backtrace || []
      if config.backtrace_filter
        filtered = backtrace.select { |line| line.include?(config.backtrace_filter) }
        backtrace = filtered unless filtered.empty?
      end

      backtrace.first(10).each { |line| puts "  #{line}" }
      puts "  ... (#{backtrace.size - 10} more lines)" if backtrace.size > 10

      unless extra_context.empty?
        puts "\nExtra context:"
        extra_context.each { |key, value| puts "  #{key}: #{value.inspect}" }
      end

      puts "=" * 80 + "\n"
    end
  end
end
