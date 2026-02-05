# frozen_string_literal: true

require "spec_helper"

RSpec.describe BugTracker::Configuration do
  subject(:config) { described_class.new }

  describe "defaults" do
    it "sets adapter to :sentry" do
      expect(config.adapter).to eq(:sentry)
    end

    it "sets enabled_environments to production and staging" do
      expect(config.enabled_environments).to eq(%w[production staging])
    end

    it "sets backtrace_filter to nil" do
      expect(config.backtrace_filter).to be_nil
    end

    it "sets development_mode based on environment" do
      expect(config.development_mode).to be_in([true, false])
    end
  end

  describe "#enabled?" do
    context "when Rails is not defined" do
      it "returns true" do
        expect(config.enabled?).to eq(true)
      end
    end

    context "when Rails is defined" do
      before do
        stub_const("Rails", Class.new)
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new(env))
      end

      context "in production environment" do
        let(:env) { "production" }

        it "returns true" do
          expect(config.enabled?).to eq(true)
        end
      end

      context "in staging environment" do
        let(:env) { "staging" }

        it "returns true" do
          expect(config.enabled?).to eq(true)
        end
      end

      context "in development environment" do
        let(:env) { "development" }

        it "returns false" do
          expect(config.enabled?).to eq(false)
        end
      end

      context "in test environment" do
        let(:env) { "test" }

        it "returns false" do
          expect(config.enabled?).to eq(false)
        end
      end
    end
  end
end
