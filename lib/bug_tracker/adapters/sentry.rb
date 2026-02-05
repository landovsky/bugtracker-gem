# frozen_string_literal: true

module BugTracker
  module Adapters
    class Sentry < Base
      def notify(exception, **context)
        return unless config.enabled?

        # Use either set_user or user_context depending on Sentry version
        ::Sentry.capture_exception(exception, extra: context)
      end

      def extra_context(**context)
        return unless config.enabled?

        ::Sentry.set_extras(context)
      end

      def user_context(hash)
        return unless config.enabled?

        # Support both old and new Sentry API
        if ::Sentry.respond_to?(:set_user)
          ::Sentry.set_user(hash)
        else
          ::Sentry.user_context(hash)
        end
      end

      def last_event_id(error = nil)
        return nil unless config.enabled?

        # Check if error was ignored by Sentry
        event_id = ::Sentry.last_event_id
        return nil if event_id.nil? || event_id.empty?

        event_id
      end
    end
  end
end
