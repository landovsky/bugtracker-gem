# BugTracker

A unified, extensible error tracking gem for Rails applications. Provides a clean adapter pattern for multiple error tracking providers (Sentry, Bugsnag, etc.) with integrated BaseError support.

## Features

- **Zero-config setup**: Works out of the box with smart defaults
- **Adapter pattern**: Easy to switch between error tracking providers
- **Auto-detection**: Automatically detects Rails app name for backtrace filtering
- **BaseError included**: Integrated error class with context storage and JSON serialization
- **Bug-free**: Fixes critical `extra_context` bug found in legacy implementations
- **Development-friendly**: Console logging in development mode
- **Production-ready**: Enabled only in production/staging by default

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bug_tracker', git: 'https://github.com/landovsky/bugtracker-gem'
```

And then execute:

```bash
bundle install
```

If using Sentry, also add:

```ruby
gem 'sentry-ruby'
```

## Usage

### Basic Usage (No Configuration Needed!)

```ruby
# Notify about an exception
begin
  # some code that might fail
rescue => e
  BugTracker.notify(e, user_id: current_user.id, order_id: order.id)
end

# Add extra context
BugTracker.extra_context(request_id: request.uuid, ip: request.remote_ip)

# Set user context
BugTracker.user_context(id: current_user.id, email: current_user.email)

# Get last event ID (for user feedback)
event_id = BugTracker.last_event_id
```

### Using BugTracker::BaseError

```ruby
class ClientError < BugTracker::BaseError
  ERROR_CODE = 502
end

class NotFoundError < BugTracker::BaseError
  ERROR_CODE = 404
end

# Raise with context
raise ClientError.new('API request failed', code: response.code, response: response.body)

# The context is automatically captured and sent to your error tracker
begin
  raise NotFoundError.new('User not found', user_id: params[:id])
rescue => e
  BugTracker.notify(e)
  render json: e.as_json, status: e.error_code
end
```

### Optional Configuration

Create an initializer at `config/initializers/bug_tracker.rb`:

```ruby
BugTracker.configure do |config|
  # Adapter (default: :sentry)
  config.adapter = :sentry  # or :bugsnag, :null, or custom adapter instance

  # Enabled environments (default: production and staging)
  config.enabled_environments = %w[production staging]

  # Backtrace filter (default: auto-detected from Rails app name)
  config.backtrace_filter = 'my_app'

  # Custom logger (default: Rails.logger)
  config.logger = Logger.new(STDOUT)
end
```

## Configuration Options

### `adapter`
The error tracking provider to use. Built-in adapters:
- `:sentry` (default) - Sentry adapter (requires `sentry-ruby` gem)
- `:null` - No-op adapter for testing

### `enabled_environments`
Array of environment names where errors should be sent to the tracking service.
Default: `['production', 'staging']`

In other environments, errors are logged to console only.

### `backtrace_filter`
String to filter backtrace lines in development mode console output.
Default: Auto-detected from Rails application name (e.g., 'pharmacy', 'hriste')

### `development_mode`
Boolean indicating if running in development mode (affects console logging).
Default: Auto-detected from `Rails.env.development?`

## Custom Adapters

You can create your own adapter for other error tracking services:

```ruby
class BugsnagAdapter < BugTracker::Adapters::Base
  def notify(exception, **context)
    return unless config.enabled?
    Bugsnag.notify(exception) do |report|
      report.add_metadata(:custom, context)
    end
  end

  def extra_context(**context)
    return unless config.enabled?
    Bugsnag.add_metadata(:extra, context)
  end

  def user_context(hash)
    return unless config.enabled?
    Bugsnag.set_user(hash[:id], hash[:email], hash[:name])
  end

  def last_event_id(error = nil)
    # Bugsnag doesn't provide event IDs in the same way
    nil
  end
end

# Use it:
BugTracker.configure do |config|
  config.adapter = BugsnagAdapter.new(config)
end
```

## API Reference

### `BugTracker.notify(exception, **context)`
Send an exception to the error tracking service with optional context.

**Parameters:**
- `exception` - The exception to track
- `**context` - Additional context (merged with exception's `extra_context` if available)

**Returns:** Event ID or nil

### `BugTracker.extra_context(**context)`
Set extra context for subsequent errors.

**Parameters:**
- `**context` - Key-value pairs to attach to future errors

### `BugTracker.user_context(hash)`
Set user context for subsequent errors.

**Parameters:**
- `hash` - User information (typically `id`, `email`, `username`, etc.)

### `BugTracker.last_event_id(error = nil)`
Get the ID of the last tracked event.

**Returns:** Event ID string or nil

## BaseError API

### Class Definition

```ruby
class MyCustomError < BugTracker::BaseError
  ERROR_CODE = 422  # HTTP status code or custom error code
end
```

### Instance Methods

#### `initialize(message = nil, **context)`
Create a new error with optional message and context.

```ruby
raise MyCustomError.new('Something went wrong', user_id: 123, details: 'extra info')
```

#### `error_code`
Returns the ERROR_CODE constant from the class.

#### `extra_context`
Returns the hash of context data passed to `initialize`.

#### `as_json(options = {})`
Returns a JSON-serializable hash representation.

**Options:**
- `backtrace: true` - Include backtrace in output

```ruby
error.as_json
# => {error: "my_custom_error", error_code: 422, message: "Something went wrong", user_id: 123, details: "extra info"}

error.as_json(backtrace: true)
# => Same as above plus backtrace: [...]
```

#### `to_json(options = {})`
Returns JSON string representation.

## Development Mode

In development mode, errors are logged to the console with:
- Exception class and message
- Filtered backtrace (top 10 lines from your app)
- Extra context data

Example output:
```
================================================================================
BugTracker: ClientError: API request failed
================================================================================
  app/services/api_client.rb:45:in `fetch_data'
  app/controllers/orders_controller.rb:12:in `create'
  ...

Extra context:
  code: 502
  response: "Bad Gateway"
  user_id: 123
================================================================================
```

## Migration from Legacy BugTracker

If you have an existing `bug_tracker.rb` file in your Rails app:

1. Add the gem to your Gemfile
2. Run `bundle install`
3. Remove your local `app/models/bug_tracker.rb` or `lib/bug_tracker.rb`
4. Update `BaseError` references to `BugTracker::BaseError`
5. Test in development and staging before deploying to production

### Automated Migration

Use the included migration script:

```bash
ruby /path/to/bug-tracker/bin/migrate_projects.rb --dry-run
```

See the script for more options.

## The Bug Fix

This gem fixes a critical bug found in some legacy implementations:

**Before (broken):**
```ruby
# In notify method - line would lose extra_context data
extra_context = e.extra_context.fetch(:context, {})
# This tried to fetch a :context key that doesn't exist!
```

**After (fixed):**
```ruby
extra_context = exception.respond_to?(:extra_context) ? exception.extra_context : {}
extra_context = {} unless extra_context.is_a?(Hash)
# Now correctly captures all context data from BaseError
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/landovsky/bugtracker-gem.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
