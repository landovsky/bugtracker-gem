# frozen_string_literal: true

module BugTracker
  module Adapters
    class Base
      def initialize(config)
        @config = config
      end

      def notify(exception, **context)
        raise NotImplementedError, "Subclasses must implement #notify"
      end

      def extra_context(**context)
        raise NotImplementedError, "Subclasses must implement #extra_context"
      end

      def user_context(hash)
        raise NotImplementedError, "Subclasses must implement #user_context"
      end

      def last_event_id(error = nil)
        raise NotImplementedError, "Subclasses must implement #last_event_id"
      end

      protected

      attr_reader :config
    end
  end
end
