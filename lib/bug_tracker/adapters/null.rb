# frozen_string_literal: true

module BugTracker
  module Adapters
    class Null < Base
      def notify(exception, **context)
        # No-op for development/test environments
        nil
      end

      def extra_context(**context)
        # No-op
      end

      def user_context(hash)
        # No-op
      end

      def last_event_id(error = nil)
        nil
      end
    end
  end
end
