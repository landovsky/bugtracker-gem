# BugTracker Gem - TODO / Next Steps

## Status: ✅ Implementation Complete, Ready for Testing & Migration

### Completed ✅

- [x] Core gem implementation (9 source files)
- [x] Test suite (5 spec files)
- [x] Bug fix for extra_context handling
- [x] Adapter pattern (Sentry, Null)
- [x] BaseError integration
- [x] Rails Railtie auto-configuration
- [x] Comprehensive documentation (6 files)
- [x] Automated migration script
- [x] Bug verification script
- [x] GitHub repository setup
- [x] Code pushed to GitHub
- [x] Version tagged (v0.1.0)

### Next Steps 🚀

#### 1. Manual Testing with One Project

- [ ] Choose test project (pharmacy or remai recommended)
- [ ] Create test branch
- [ ] Add gem to Gemfile
- [ ] Run bundle install
- [ ] Remove local bug_tracker.rb and base_error.rb
- [ ] Update BaseError → BugTracker::BaseError
- [ ] Run test suite: `bundle exec rspec`
- [ ] Test in development (trigger error, check console)
- [ ] Deploy to staging
- [ ] Verify Sentry integration
- [ ] Check that all context is captured
- [ ] Monitor for 24 hours

#### 2. Automated Migration (After Successful Test)

- [ ] Run dry-run: `./bin/migrate_projects.rb --dry-run`
- [ ] Review preview output for all 8 projects
- [ ] Execute migration: `./bin/migrate_projects.rb`
- [ ] Verify branches created for all projects

#### 3. Pull Request Creation

For each of the 8 projects:
- [ ] medicmee-doc
- [ ] pharmacy
- [ ] hriste (⚠️ HAS BUG - Priority)
- [ ] hriste-sync (⚠️ HAS BUG - Priority)
- [ ] remai
- [ ] siposervis (⚠️ HAS BUG - Priority)
- [ ] remai-light
- [ ] medicmee-pac

Tasks per project:
- [ ] Review changes in branch
- [ ] Create Pull Request on GitHub
- [ ] Add description explaining changes
- [ ] Link to bugtracker-gem repository
- [ ] Add testing checklist

#### 4. Testing & Verification

For each PR:
- [ ] Code review
- [ ] Run tests in CI
- [ ] Deploy to staging
- [ ] Trigger test error
- [ ] Verify Sentry receives error with full context
- [ ] Check user context is set
- [ ] Verify backtrace filtering
- [ ] Monitor for 24 hours
- [ ] Get approval

#### 5. Deployment

For each project:
- [ ] Merge PR to main
- [ ] Deploy to production
- [ ] Monitor Sentry for 48 hours
- [ ] Verify no errors lost
- [ ] Check that bug is fixed (for hriste, hriste-sync, siposervis)

### Priority Order

1. **Test Phase** (1 project)
   - pharmacy or remai (no bugs, good for testing)

2. **High Priority** (3 projects with bugs)
   - hriste
   - hriste-sync
   - siposervis

3. **Standard Migration** (4 remaining projects)
   - medicmee-doc
   - remai-light
   - medicmee-pac
   - (and the non-tested one from step 1)

### Success Criteria

- [ ] All 8 projects migrated successfully
- [ ] All test suites passing
- [ ] No errors lost in production
- [ ] Bug fixed in hriste, hriste-sync, siposervis
- [ ] Full context captured in Sentry for all projects
- [ ] Development logging working correctly
- [ ] User context working correctly
- [ ] Zero regressions

### Future Improvements (Optional)

- [ ] Add Bugsnag adapter
- [ ] Add more comprehensive tests
- [ ] Add performance benchmarks
- [ ] Publish to RubyGems (optional)
- [ ] Add CI/CD for the gem itself
- [ ] Add code coverage reporting
- [ ] Create video walkthrough
- [ ] Write blog post about the migration

### Notes

- **Repository**: https://github.com/landovsky/bugtracker-gem
- **Version**: 0.1.0
- **Installation**: `gem 'bug_tracker', git: 'https://github.com/landovsky/bugtracker-gem'`
- **Migration Script**: `/Users/tomas/git/gems/bug-tracker/bin/migrate_projects.rb`
- **Verification Script**: `/Users/tomas/git/gems/bug-tracker/bin/verify_bug_fix.rb`

### Timeline Estimate

- Manual testing: 2-4 hours
- Automated migration: 30 minutes
- PR creation: 1 hour
- Review & testing: 2-3 days (per project)
- Deployment: 1 week (all projects)

**Total**: 2-3 weeks for complete migration of all 8 projects

### Questions / Issues

(Add any questions or issues that arise during migration here)

---

**Last Updated**: 2026-02-05
**Status**: Ready for testing phase
