# frozen_string_literal: true

require "spec_helper"

RSpec.describe BugTracker::Adapters::Null do
  let(:config) { BugTracker::Configuration.new }
  subject(:adapter) { described_class.new(config) }

  describe "#notify" do
    it "returns nil" do
      exception = StandardError.new("test")
      result = adapter.notify(exception, foo: "bar")
      expect(result).to be_nil
    end

    it "does not raise errors" do
      exception = StandardError.new("test")
      expect { adapter.notify(exception) }.not_to raise_error
    end
  end

  describe "#extra_context" do
    it "does not raise errors" do
      expect { adapter.extra_context(foo: "bar") }.not_to raise_error
    end
  end

  describe "#user_context" do
    it "does not raise errors" do
      expect { adapter.user_context(id: 123) }.not_to raise_error
    end
  end

  describe "#last_event_id" do
    it "returns nil" do
      expect(adapter.last_event_id).to be_nil
    end
  end
end
