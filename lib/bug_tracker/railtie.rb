# frozen_string_literal: true

module BugTracker
  class Railtie < Rails::Railtie
    config.before_initialize do
      # Auto-detect backtrace filter from Rails application name
      if BugTracker.configuration.backtrace_filter.nil?
        app_name = Rails.application.class.module_parent_name.underscore
        BugTracker.configuration.backtrace_filter = app_name
      end
    end
  end
end
