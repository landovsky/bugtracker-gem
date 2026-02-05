# frozen_string_literal: true

require "bug_tracker"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Reset configuration before each test
  config.before(:each) do
    BugTracker.instance_variable_set(:@configuration, nil)
    BugTracker.instance_variable_set(:@context_manager, nil)
    BugTracker.instance_variable_set(:@adapter, nil)
  end
end
