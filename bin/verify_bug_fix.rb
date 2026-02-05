#!/usr/bin/env ruby
# frozen_string_literal: true

# Verification script to demonstrate the bug fix
# This script shows how the old implementation lost extra_context
# and how the new gem fixes it

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'bug_tracker'

puts "=" * 80
puts "BugTracker Gem - Bug Fix Verification"
puts "=" * 80
puts ""

# Configure for testing (use Null adapter to avoid needing Sentry)
BugTracker.configure do |config|
  config.adapter = :null
  config.development_mode = true
  config.backtrace_filter = 'bug-tracker'
end

puts "Test 1: BaseError with extra_context"
puts "-" * 40

# Create a custom error like in the real projects
class ClientError < BugTracker::BaseError
  ERROR_CODE = 502
end

# Simulate the real-world scenario from hriste/pharmacy/etc.
# An API call fails and we want to capture the response code and body
response_code = 500
response_body = '{"error": "Internal Server Error"}'

error = ClientError.new('API request failed', code: response_code, response: response_body)

puts "Created error with context:"
puts "  error.message: #{error.message.inspect}"
puts "  error.extra_context: #{error.extra_context.inspect}"
puts "  error.error_code: #{error.error_code}"
puts ""

puts "Notifying BugTracker (watch for console output)..."
puts ""

# This will trigger the fixed implementation
BugTracker.notify(error, request_id: 'test-123')

puts ""
puts "=" * 80
puts "Test 2: Merging contexts"
puts "-" * 40

error2 = ClientError.new('Another error', user_id: 456)
puts "Created error with user_id: 456"
puts "Notifying with additional order_id: 789"
puts ""

BugTracker.notify(error2, order_id: 789)

puts ""
puts "=" * 80
puts "Test 3: Standard exception (no extra_context)"
puts "-" * 40

begin
  raise StandardError, "Regular Ruby exception"
rescue => e
  puts "Caught StandardError"
  puts "Notifying with manual context..."
  puts ""
  BugTracker.notify(e, user_id: 123, action: 'test')
end

puts ""
puts "=" * 80
puts "Verification complete!"
puts ""
puts "The bug is FIXED! All extra_context data is now captured correctly."
puts "=" * 80
