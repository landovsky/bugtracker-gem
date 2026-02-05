# frozen_string_literal: true

require "spec_helper"

RSpec.describe BugTracker::ContextManager do
  let(:config) { BugTracker::Configuration.new }
  let(:adapter) { BugTracker::Adapters::Null.new(config) }
  subject(:manager) { described_class.new(adapter, config) }

  describe "#notify" do
    context "with standard exception" do
      let(:exception) { StandardError.new("test error") }

      it "calls adapter notify" do
        expect(adapter).to receive(:notify).with(exception, hash_including(foo: "bar"))
        manager.notify(exception, foo: "bar")
      end
    end

    context "with BaseError having extra_context" do
      let(:exception) do
        BugTracker::BaseError.new("test", user_id: 123, response_code: 500)
      end

      it "extracts extra_context correctly" do
        expect(adapter).to receive(:notify).with(
          exception,
          hash_including(user_id: 123, response_code: 500)
        )
        manager.notify(exception)
      end

      it "merges extra_context with passed context" do
        expect(adapter).to receive(:notify).with(
          exception,
          hash_including(user_id: 123, response_code: 500, order_id: 456)
        )
        manager.notify(exception, order_id: 456)
      end

      it "passed context overrides extra_context" do
        expect(adapter).to receive(:notify).with(
          exception,
          hash_including(user_id: 999, response_code: 500)
        )
        manager.notify(exception, user_id: 999)
      end
    end

    context "with exception having non-hash extra_context" do
      let(:exception) do
        err = StandardError.new("test")
        err.define_singleton_method(:extra_context) { "not a hash" }
        err
      end

      it "handles gracefully" do
        expect(adapter).to receive(:notify).with(exception, hash_including(foo: "bar"))
        manager.notify(exception, foo: "bar")
      end
    end

    context "in development mode" do
      before { config.development_mode = true }

      it "logs to console" do
        exception = StandardError.new("test error")

        expect { manager.notify(exception, foo: "bar") }.to output(/BugTracker: StandardError: test error/).to_stdout
      end

      it "includes extra context in log" do
        exception = BugTracker::BaseError.new("test", user_id: 123)

        expect { manager.notify(exception) }.to output(/user_id: 123/).to_stdout
      end

      context "with backtrace filter" do
        before { config.backtrace_filter = "my_app" }

        it "filters backtrace to app lines" do
          exception = StandardError.new("test")
          exception.set_backtrace([
            "/path/to/my_app/controllers/foo.rb:10",
            "/gems/rack/lib/rack.rb:20",
            "/path/to/my_app/models/bar.rb:30",
            "/gems/rails/lib/rails.rb:40"
          ])

          output = capture_stdout { manager.notify(exception) }
          expect(output).to include("my_app/controllers/foo.rb:10")
          expect(output).to include("my_app/models/bar.rb:30")
          expect(output).not_to include("rack/lib/rack.rb")
        end
      end
    end

    context "not in development mode" do
      before { config.development_mode = false }

      it "does not log to console" do
        exception = StandardError.new("test error")

        expect { manager.notify(exception) }.not_to output.to_stdout
      end
    end
  end

  describe "#extra_context" do
    it "delegates to adapter" do
      expect(adapter).to receive(:extra_context).with(foo: "bar")
      manager.extra_context(foo: "bar")
    end
  end

  describe "#user_context" do
    it "delegates to adapter" do
      expect(adapter).to receive(:user_context).with(id: 123)
      manager.user_context(id: 123)
    end
  end

  describe "#last_event_id" do
    it "delegates to adapter" do
      expect(adapter).to receive(:last_event_id).with(nil)
      manager.last_event_id
    end
  end

  private

  def capture_stdout
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end
end
