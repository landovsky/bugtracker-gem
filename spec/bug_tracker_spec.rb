# frozen_string_literal: true

require "spec_helper"

RSpec.describe BugTracker do
  it "has a version number" do
    expect(BugTracker::VERSION).not_to be nil
  end

  describe ".configure" do
    it "yields configuration" do
      expect { |b| BugTracker.configure(&b) }.to yield_with_args(BugTracker::Configuration)
    end

    it "allows setting adapter" do
      BugTracker.configure do |config|
        config.adapter = :null
      end

      expect(BugTracker.configuration.adapter).to eq(:null)
    end
  end

  describe ".notify" do
    let(:exception) { StandardError.new("test error") }

    it "delegates to context manager" do
      BugTracker.configure { |c| c.adapter = :null }

      expect { BugTracker.notify(exception, foo: "bar") }.not_to raise_error
    end
  end

  describe ".extra_context" do
    it "delegates to context manager" do
      BugTracker.configure { |c| c.adapter = :null }

      expect { BugTracker.extra_context(foo: "bar") }.not_to raise_error
    end
  end

  describe ".user_context" do
    it "delegates to context manager" do
      BugTracker.configure { |c| c.adapter = :null }

      expect { BugTracker.user_context(id: 123) }.not_to raise_error
    end
  end

  describe ".last_event_id" do
    it "delegates to context manager" do
      BugTracker.configure { |c| c.adapter = :null }

      result = BugTracker.last_event_id
      expect(result).to be_nil
    end
  end
end
