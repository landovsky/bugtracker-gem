# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-02-05

### Added
- Initial release of BugTracker gem
- Sentry adapter with support for both old and new API
- Null adapter for development/testing
- Integrated BugTracker::BaseError class
- Rails Railtie for automatic configuration
- Auto-detection of Rails application name for backtrace filtering
- Development mode console logging with backtrace filtering
- Zero-config setup with smart defaults
- Configuration system with customizable adapters
- Bug fix for extra_context handling in legacy implementations

### Features
- `BugTracker.notify(exception, **context)` - Send errors to tracking service
- `BugTracker.extra_context(**context)` - Set additional context
- `BugTracker.user_context(hash)` - Set user information
- `BugTracker.last_event_id(error)` - Get last event ID for user feedback
- `BugTracker::BaseError` - Base error class with context and JSON serialization
- Extensible adapter pattern for adding new providers

[0.1.0]: https://github.com/yourusername/bug-tracker/releases/tag/v0.1.0
