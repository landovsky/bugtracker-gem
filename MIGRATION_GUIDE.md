# Migration Guide: Local BugTracker → BugTracker Gem

This guide explains how to migrate from a local BugTracker implementation to the BugTracker gem.

## Quick Start

For most projects, use the automated migration script:

```bash
cd /Users/tomas/git/gems/bug-tracker
./bin/migrate_projects.rb --dry-run  # Preview changes
./bin/migrate_projects.rb            # Run migration
```

## Manual Migration

If you prefer to migrate manually or need to customize the process:

### 1. Add the Gem

Add to your `Gemfile`:

```ruby
gem 'bug_tracker', git: 'https://github.com/landovsky/bugtracker-gem'
```

Run:
```bash
bundle install
```

### 2. Remove Local Files

Remove these files if they exist in your project:
- `app/models/bug_tracker.rb`
- `app/services/bug_tracker.rb`
- `lib/bug_tracker.rb`
- `app/models/base_error.rb`
- `lib/base_error.rb`

### 3. Update BaseError References

Find all files that reference `BaseError`:
```bash
grep -r "BaseError" app/ lib/ --include="*.rb"
```

Update them to use `BugTracker::BaseError`:

**Before:**
```ruby
class ClientError < BaseError
  ERROR_CODE = 502
end
```

**After:**
```ruby
class BugTracker::BaseError
  ERROR_CODE = 502
end
```

### 4. Verify BugTracker Calls

Your existing BugTracker calls should work without changes:

```ruby
BugTracker.notify(e, user_id: current_user.id)
BugTracker.extra_context(request_id: request.uuid)
BugTracker.user_context(email: user.email)
```

### 5. Test

1. Run your test suite:
   ```bash
   bundle exec rspec
   ```

2. Start the Rails server and check logs:
   ```bash
   rails s
   ```

3. Trigger an error in development - you should see formatted output in console

4. Deploy to staging and verify Sentry integration

## Project-Specific Notes

### Projects with the Bug (hriste, hriste-sync, siposervis)

These projects have the critical bug on line 9:
```ruby
extra_context = e.extra_context.fetch(:context, {})  # BROKEN
```

After migration, HTTP response details will be correctly captured:
```ruby
raise ClientError.new('failed', code: 500, response: body)
# Before: context = {} (lost!)
# After:  context = {code: 500, response: body} ✅
```

### Projects with Additional Logging (siposervis)

The gem already includes development logging, so you can remove:
```ruby
Rails.logger.error(e.message) if Rails.env.production?
```

The gem logs in development mode automatically and sends to Sentry in production.

### Projects with Custom Constants (hriste, hriste-sync)

If you have constants like:
```ruby
FRIENDLY_ERROR_MESSAGE = "Something went wrong..."
```

Move them to your application code (e.g., `ApplicationController` or a concern).

## Configuration (Optional)

The gem works without configuration, but you can customize:

Create `config/initializers/bug_tracker.rb`:

```ruby
BugTracker.configure do |config|
  # Default adapter (auto-detected if sentry-ruby is installed)
  config.adapter = :sentry

  # Enabled environments (default: production, staging)
  config.enabled_environments = %w[production staging]

  # Backtrace filter (auto-detected from Rails.application.class)
  # config.backtrace_filter = 'my_app'
end
```

## Verification Checklist

After migrating each project:

- [ ] Tests pass: `bundle exec rspec`
- [ ] Server starts: `rails s`
- [ ] Development errors show in console with formatted output
- [ ] Grep confirms no local `bug_tracker.rb` files exist
- [ ] Grep confirms all `BaseError` references are now `BugTracker::BaseError`
- [ ] Staging deployment successful
- [ ] Sentry receives errors in staging with full context
- [ ] User context is set correctly in Sentry
- [ ] No errors are lost

## Rollback

If you need to rollback:

1. Revert the migration commit:
   ```bash
   git revert <commit-hash>
   ```

2. Or restore from backup:
   ```bash
   git checkout main
   git branch -D chore/migrate-to-bug-tracker-gem
   ```

## Support

Issues or questions:
- Check the [README](README.md) for API documentation
- Review the [verification script](bin/verify_bug_fix.rb) for examples
- Open an issue on GitHub

## Projects to Migrate

Based on exploration, these 8 projects need migration:

1. **medicmee-doc** ✓ No bug
2. **pharmacy** ✓ No bug
3. **hriste** ⚠️ Has bug (line 9)
4. **hriste-sync** ⚠️ Has bug (line 9)
5. **remai** ✓ No bug
6. **siposervis** ⚠️ Has bug (line 9) + extra logging
7. **remai-light** ✓ No bug
8. **medicmee-pac** ✓ No bug

Priority: Start with pharmacy or remai (no bugs), verify it works, then migrate the others.
