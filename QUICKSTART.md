# BugTracker Gem - Quick Start Guide

## For Project Maintainers

### Automated Migration (Recommended)

1. **Preview changes:**
   ```bash
   cd /Users/tomas/git/gems/bug-tracker
   ./bin/migrate_projects.rb --dry-run
   ```

2. **Execute migration:**
   ```bash
   ./bin/migrate_projects.rb
   ```

3. **Review and merge PRs** created for each project

### Manual Migration (If Preferred)

1. **Add to Gemfile:**
   ```ruby
   gem 'bug_tracker', git: 'https://github.com/landovsky/bugtracker-gem'
   ```

2. **Install:**
   ```bash
   bundle install
   ```

3. **Remove local files:**
   ```bash
   rm app/models/bug_tracker.rb
   rm app/models/base_error.rb
   ```

4. **Update references:**
   ```bash
   # Find all files
   grep -r "BaseError" app/ lib/ --include="*.rb"

   # Update: class FooError < BaseError
   # To:     class FooError < BugTracker::BaseError
   ```

5. **Test:**
   ```bash
   bundle exec rspec
   rails s  # Trigger an error, check console output
   ```

## For New Projects

Just add to Gemfile and it works:

```ruby
gem 'bug_tracker', git: 'https://github.com/landovsky/bugtracker-gem'
gem 'sentry-ruby'  # Optional: if using Sentry
```

## Usage

```ruby
# Define custom errors
class ClientError < BugTracker::BaseError
  ERROR_CODE = 502
end

# Use in controllers
def create
  @order = Order.create!(params)
rescue => e
  BugTracker.notify(e, user_id: current_user.id)
  redirect_to orders_path, alert: "Failed"
end

# Set user context (in ApplicationController)
before_action :set_bug_tracker_context

def set_bug_tracker_context
  return unless current_user
  BugTracker.user_context(id: current_user.id, email: current_user.email)
end
```

## Configuration (Optional)

Create `config/initializers/bug_tracker.rb`:

```ruby
BugTracker.configure do |config|
  config.adapter = :sentry  # Default
  config.enabled_environments = %w[production staging]  # Default
end
```

## Verification

### In Development
Start server and trigger an error - you should see:
```
================================================================================
BugTracker: YourError: error message
================================================================================
  app/controllers/foo_controller.rb:10:in `create'
  ...

Extra context:
  user_id: 123
  order_id: 456
================================================================================
```

### In Staging/Production
Trigger an error and check Sentry - all context should be present:
- Exception message
- User information (if set with `user_context`)
- Extra context (from `extra_context` or passed to `notify`)
- HTTP details for `BaseError` instances

## The Bug That's Fixed

**Before (broken in hriste, hriste-sync, siposervis):**
```ruby
raise ClientError.new('failed', code: 500, response: 'Error body')
# Context sent to Sentry: {} (LOST!)
```

**After (with gem):**
```ruby
raise ClientError.new('failed', code: 500, response: 'Error body')
# Context sent to Sentry: {code: 500, response: 'Error body'} ✅
```

## Getting Help

- **Full documentation:** [README.md](README.md)
- **Migration guide:** [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)
- **Real examples:** [EXAMPLES.md](EXAMPLES.md)
- **Run verification:** `ruby bin/verify_bug_fix.rb`

## Testing the Gem

```bash
cd /Users/tomas/git/gems/bug-tracker

# Run verification script
ruby bin/verify_bug_fix.rb

# Run test suite (when you have dependencies)
# bundle install
# bundle exec rspec
```

## Projects Being Migrated

8 projects will be updated:
- medicmee-doc, pharmacy, remai, remai-light, medicmee-pac
- **hriste, hriste-sync, siposervis** (these have the bug!)

## Timeline

1. **Today:** Create GitHub repo, push code
2. **This week:** Test with one project (pharmacy or remai)
3. **Next week:** Migrate all 8 projects
4. **Ongoing:** Maintain single gem instead of 8+ copies

## Support

Questions or issues? Check the documentation or open a GitHub issue.
