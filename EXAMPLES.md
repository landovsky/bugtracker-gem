# BugTracker Gem Examples

Real-world examples of using the BugTracker gem.

## Basic Usage

### Notifying About Exceptions

```ruby
class OrdersController < ApplicationController
  def create
    @order = Order.create!(order_params)
    redirect_to @order
  rescue => e
    BugTracker.notify(e,
      user_id: current_user.id,
      order_params: order_params.to_json
    )
    redirect_to orders_path, alert: "Failed to create order"
  end
end
```

### Using BaseError with Context

```ruby
# Define custom errors
class ClientError < BugTracker::BaseError
  ERROR_CODE = 502
end

class NotFoundError < BugTracker::BaseError
  ERROR_CODE = 404
end

class ValidationError < BugTracker::BaseError
  ERROR_CODE = 422
end

# Use in API clients
class ApiClient
  def fetch_data(url)
    response = HTTParty.get(url)

    unless response.success?
      raise ClientError.new(
        'API request failed',
        url: url,
        code: response.code,
        response: response.body
      )
    end

    response.parsed_response
  rescue ClientError => e
    BugTracker.notify(e, service: 'external_api')
    raise
  end
end
```

### Setting User Context

```ruby
class ApplicationController < ActionController::Base
  before_action :set_user_context

  private

  def set_user_context
    return unless current_user

    BugTracker.user_context(
      id: current_user.id,
      email: current_user.email,
      username: current_user.username
    )
  end
end
```

### Adding Extra Context

```ruby
class CheckoutsController < ApplicationController
  def create
    BugTracker.extra_context(
      request_id: request.uuid,
      ip: request.remote_ip,
      user_agent: request.user_agent
    )

    @checkout = Checkout.new(checkout_params)

    if @checkout.save
      redirect_to success_path
    else
      # Any errors raised here will include the extra context
      raise ValidationError.new('Checkout failed', errors: @checkout.errors.full_messages)
    end
  end
end
```

## Advanced Usage

### Capturing Event ID for User Feedback

```ruby
class ErrorsController < ApplicationController
  def handle_error
    begin
      dangerous_operation
    rescue => e
      BugTracker.notify(e, action: 'dangerous_operation')
      event_id = BugTracker.last_event_id

      if event_id
        flash[:error] = "An error occurred. Reference ID: #{event_id}"
        # You can use this ID for user support tickets
      else
        flash[:error] = "An error occurred. Please try again."
      end

      redirect_to root_path
    end
  end
end
```

### Error Handling in Background Jobs

```ruby
class DataSyncJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)

    BugTracker.user_context(
      id: user.id,
      email: user.email
    )

    BugTracker.extra_context(
      job: self.class.name,
      queue: queue_name
    )

    sync_data(user)
  rescue => e
    BugTracker.notify(e, user_id: user_id)
    raise # Re-raise to trigger job retry
  end
end
```

### JSON API Error Responses

```ruby
class Api::V1::BaseController < ActionController::API
  rescue_from BugTracker::BaseError, with: :render_base_error
  rescue_from StandardError, with: :render_standard_error

  private

  def render_base_error(error)
    BugTracker.notify(error,
      endpoint: "#{controller_name}##{action_name}",
      params: params.to_unsafe_h
    )

    render json: error.as_json, status: error.error_code
  end

  def render_standard_error(error)
    BugTracker.notify(error,
      endpoint: "#{controller_name}##{action_name}",
      params: params.to_unsafe_h
    )

    render json: {
      error: 'internal_server_error',
      message: 'An unexpected error occurred'
    }, status: 500
  end
end
```

### Custom Error Classes with Default Context

```ruby
class PaymentError < BugTracker::BaseError
  ERROR_CODE = 402

  def initialize(message, **context)
    # Add default context for all payment errors
    context[:service] = 'payment_gateway'
    context[:timestamp] = Time.current.iso8601
    super(message, **context)
  end
end

# Usage
raise PaymentError.new('Card declined',
  card_last4: '1234',
  amount: 99.99,
  currency: 'USD'
)
# Extra context will include: service, timestamp, card_last4, amount, currency
```

## Configuration Examples

### Development Environment (config/environments/development.rb)

```ruby
Rails.application.configure do
  # ... other config

  # Optional: customize development logging
  BugTracker.configure do |config|
    config.development_mode = true
    config.backtrace_filter = 'pharmacy' # Show only your app's backtrace
  end
end
```

### Production Environment (config/initializers/bug_tracker.rb)

```ruby
BugTracker.configure do |config|
  config.adapter = :sentry
  config.enabled_environments = %w[production staging]

  # Optional: use Rails logger
  config.logger = Rails.logger
end
```

### Custom Adapter (config/initializers/bug_tracker.rb)

```ruby
class SlackAdapter < BugTracker::Adapters::Base
  def notify(exception, **context)
    return unless config.enabled?

    # Send to Slack
    HTTParty.post(
      ENV['SLACK_WEBHOOK_URL'],
      body: {
        text: "Error: #{exception.class}: #{exception.message}",
        attachments: [{
          color: 'danger',
          fields: context.map { |k, v| { title: k, value: v, short: true } }
        }]
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  def extra_context(**context)
    # Store in thread-local variable
    Thread.current[:slack_context] = context
  end

  def user_context(hash)
    Thread.current[:slack_user] = hash
  end

  def last_event_id(error = nil)
    nil # Slack doesn't provide event IDs
  end
end

BugTracker.configure do |config|
  config.adapter = SlackAdapter.new(config)
end
```

## Testing Examples

### RSpec Examples

```ruby
RSpec.describe OrdersController, type: :controller do
  describe 'POST #create' do
    context 'when order creation fails' do
      it 'notifies BugTracker' do
        allow(Order).to receive(:create!).and_raise(StandardError, 'DB error')

        expect(BugTracker).to receive(:notify).with(
          instance_of(StandardError),
          hash_including(user_id: user.id)
        )

        post :create, params: { order: { items: [] } }
      end
    end
  end
end
```

### Testing with Null Adapter

```ruby
# spec/spec_helper.rb
RSpec.configure do |config|
  config.before(:each) do
    # Use null adapter in tests
    BugTracker.configure do |c|
      c.adapter = :null
    end
  end
end
```

### Testing BaseError

```ruby
RSpec.describe ClientError do
  it 'captures context' do
    error = ClientError.new('failed', code: 500, response: 'error')

    expect(error.error_code).to eq(502)
    expect(error.extra_context).to eq(code: 500, response: 'error')
    expect(error.as_json[:code]).to eq(500)
  end
end
```

## Real-World Scenarios

### Scenario 1: External API Integration

```ruby
class ExternalApiService
  class ApiError < BugTracker::BaseError
    ERROR_CODE = 502
  end

  def call
    response = HTTParty.get(api_url, headers: headers)

    unless response.success?
      BugTracker.extra_context(
        service: 'external_api',
        endpoint: api_url,
        response_time: response.time
      )

      raise ApiError.new(
        'API request failed',
        code: response.code,
        response: response.body,
        headers: response.headers.to_h
      )
    end

    response.parsed_response
  end
end
```

### Scenario 2: File Upload Processing

```ruby
class FileUploadProcessor
  class UploadError < BugTracker::BaseError
    ERROR_CODE = 422
  end

  def process(file, user)
    BugTracker.user_context(id: user.id, email: user.email)
    BugTracker.extra_context(
      filename: file.original_filename,
      content_type: file.content_type,
      size: file.size
    )

    validate_file!(file)
    process_file(file)
  rescue => e
    BugTracker.notify(e, operation: 'file_upload')
    raise UploadError.new('File processing failed', original_error: e.class.name)
  end

  private

  def validate_file!(file)
    raise UploadError.new('File too large') if file.size > 10.megabytes
    raise UploadError.new('Invalid type') unless valid_type?(file)
  end
end
```

### Scenario 3: Database Transaction Error Handling

```ruby
class AccountService
  def transfer(from_account, to_account, amount)
    ActiveRecord::Base.transaction do
      BugTracker.extra_context(
        from_account_id: from_account.id,
        to_account_id: to_account.id,
        amount: amount
      )

      from_account.withdraw!(amount)
      to_account.deposit!(amount)

      create_transfer_record(from_account, to_account, amount)
    end
  rescue ActiveRecord::RecordInvalid => e
    BugTracker.notify(e, operation: 'account_transfer')
    raise ValidationError.new('Transfer failed', errors: e.record.errors.full_messages)
  rescue => e
    BugTracker.notify(e, operation: 'account_transfer')
    raise
  end
end
```

## Migration Examples

### Before (Old BugTracker)

```ruby
class ApiClient
  def fetch
    # ...
  rescue => e
    extra_context = e.extra_context.fetch(:context, {})  # BUG!
    BugTracker.notify(e, extra_context)
  end
end
```

### After (BugTracker Gem)

```ruby
class ApiClient
  def fetch
    # ...
  rescue => e
    BugTracker.notify(e)  # Context automatically extracted correctly!
  end
end
```

The gem automatically extracts `extra_context` from `BugTracker::BaseError` instances, fixing the bug.
