# frozen_string_literal: true

require "spec_helper"

RSpec.describe BugTracker::BaseError do
  describe "#initialize" do
    it "accepts a message" do
      error = described_class.new("test message")
      expect(error.message).to eq("test message")
    end

    it "accepts context" do
      error = described_class.new("test", foo: "bar", baz: 123)
      expect(error.extra_context).to eq(foo: "bar", baz: 123)
    end

    it "works without message" do
      error = described_class.new(foo: "bar")
      expect(error.message).to be_nil
      expect(error.extra_context).to eq(foo: "bar")
    end
  end

  describe "#error_code" do
    it "returns ERROR_CODE constant" do
      error = described_class.new("test")
      expect(error.error_code).to eq(500)
    end

    context "with custom error class" do
      let(:custom_error_class) do
        Class.new(described_class) do
          ERROR_CODE = 404
        end
      end

      it "returns custom ERROR_CODE" do
        error = custom_error_class.new("not found")
        expect(error.error_code).to eq(404)
      end
    end
  end

  describe "#as_json" do
    let(:error) { described_class.new("test message", user_id: 123, details: "extra") }

    it "returns hash with error info" do
      json = error.as_json
      expect(json[:error]).to eq("base_error")
      expect(json[:error_code]).to eq(500)
      expect(json[:message]).to eq("test message")
    end

    it "includes extra_context" do
      json = error.as_json
      expect(json[:user_id]).to eq(123)
      expect(json[:details]).to eq("extra")
    end

    it "excludes backtrace by default" do
      json = error.as_json
      expect(json).not_to have_key(:backtrace)
    end

    it "includes backtrace when requested" do
      begin
        raise error
      rescue => e
        json = e.as_json(backtrace: true)
        expect(json[:backtrace]).to be_an(Array)
        expect(json[:backtrace]).not_to be_empty
      end
    end
  end

  describe "#to_json" do
    it "returns JSON string" do
      error = described_class.new("test", foo: "bar")
      json_string = error.to_json

      expect(json_string).to be_a(String)
      parsed = JSON.parse(json_string)
      expect(parsed["error"]).to eq("base_error")
      expect(parsed["foo"]).to eq("bar")
    end
  end

  describe "inheritance" do
    let(:custom_error_class) do
      Class.new(described_class) do
        ERROR_CODE = 422
      end
    end

    it "inherits from StandardError" do
      error = custom_error_class.new("test")
      expect(error).to be_a(StandardError)
    end

    it "can be raised and rescued" do
      expect {
        raise custom_error_class.new("test")
      }.to raise_error(custom_error_class)
    end
  end
end
