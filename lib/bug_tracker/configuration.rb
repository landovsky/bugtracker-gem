# frozen_string_literal: true

module BugTracker
  class Configuration
    attr_accessor :adapter, :logger, :enabled_environments, :backtrace_filter, :development_mode

    def initialize
      @adapter = :sentry
      @logger = defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
      @enabled_environments = %w[production staging]
      @backtrace_filter = nil # Auto-detected from Rails app name
      @development_mode = defined?(Rails) ? Rails.env.development? : (ENV['RAILS_ENV'] == 'development')
    end

    def enabled?
      return true unless defined?(Rails)
      enabled_environments.include?(Rails.env.to_s)
    end
  end
end
