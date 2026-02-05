#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'optparse'
require 'json'

# Migration script to update Rails projects to use the BugTracker gem
# This script will:
# 1. Find all projects with bug_tracker.rb
# 2. Remove local bug_tracker.rb and base_error.rb files
# 3. Add gem to Gemfile
# 4. Update BaseError references to BugTracker::BaseError
# 5. Run bundle install
# 6. Commit changes to a new branch

class ProjectMigrator
  PROJECTS_DIR = File.expand_path('~/git/projects')
  GEM_REPO_URL = 'https://github.com/yourusername/bug-tracker' # TODO: Update this after creating GitHub repo

  attr_reader :dry_run, :log_file, :projects_to_migrate

  def initialize(dry_run: false)
    @dry_run = dry_run
    @log_file = File.expand_path('~/git/gems/bug-tracker/migration.log')
    @projects_to_migrate = []

    setup_logging
  end

  def run
    log "=" * 80
    log "BugTracker Gem Migration Script"
    log "Mode: #{dry_run ? 'DRY RUN' : 'LIVE'}"
    log "=" * 80
    log ""

    find_projects

    if projects_to_migrate.empty?
      log "No projects found with bug_tracker.rb"
      return
    end

    log "Found #{projects_to_migrate.size} projects to migrate:"
    projects_to_migrate.each { |p| log "  - #{File.basename(p)}" }
    log ""

    if dry_run
      log "DRY RUN: No changes will be made"
      projects_to_migrate.each { |project| preview_migration(project) }
    else
      confirm_migration
      projects_to_migrate.each { |project| migrate_project(project) }
    end

    print_summary
  end

  private

  def setup_logging
    File.write(log_file, "Migration started at #{Time.now}\n")
  end

  def log(message)
    puts message
    File.open(log_file, 'a') { |f| f.puts(message) }
  end

  def find_projects
    return unless Dir.exist?(PROJECTS_DIR)

    Dir.entries(PROJECTS_DIR).each do |dir|
      next if dir.start_with?('.')

      project_path = File.join(PROJECTS_DIR, dir)
      next unless Dir.exist?(project_path)
      next unless Dir.exist?(File.join(project_path, '.git'))

      # Check if project has bug_tracker.rb
      bug_tracker_paths = [
        File.join(project_path, 'app/models/bug_tracker.rb'),
        File.join(project_path, 'app/services/bug_tracker.rb'),
        File.join(project_path, 'lib/bug_tracker.rb')
      ]

      if bug_tracker_paths.any? { |path| File.exist?(path) }
        projects_to_migrate << project_path
      end
    end
  end

  def preview_migration(project_path)
    project_name = File.basename(project_path)
    log "\n--- Preview: #{project_name} ---"

    Dir.chdir(project_path) do
      # Check git status
      status = `git status --porcelain`.strip
      unless status.empty?
        log "  ⚠️  WARNING: Working directory is not clean"
        log "  Git status:\n#{status.lines.map { |l| "    #{l}" }.join}"
      end

      # Find files to remove
      files_to_remove = find_files_to_remove
      if files_to_remove.any?
        log "  Files to remove:"
        files_to_remove.each { |f| log "    - #{f}" }
      end

      # Find BaseError references
      base_error_refs = find_base_error_references
      if base_error_refs.any?
        log "  Files with BaseError references (#{base_error_refs.size}):"
        base_error_refs.first(5).each { |f| log "    - #{f}" }
        log "    ... and #{base_error_refs.size - 5} more" if base_error_refs.size > 5
      end

      # Check Gemfile
      gemfile_path = File.join(project_path, 'Gemfile')
      if File.exist?(gemfile_path)
        if File.read(gemfile_path).include?("gem 'bug_tracker'")
          log "  ⚠️  Gemfile already has bug_tracker gem"
        else
          log "  Will add to Gemfile: gem 'bug_tracker', git: '#{GEM_REPO_URL}'"
        end
      end
    end
  end

  def migrate_project(project_path)
    project_name = File.basename(project_path)
    log "\n--- Migrating: #{project_name} ---"

    Dir.chdir(project_path) do
      # Check git status
      status = `git status --porcelain`.strip
      unless status.empty?
        log "  ❌ ERROR: Working directory is not clean. Skipping."
        return
      end

      # Get current branch
      current_branch = `git branch --show-current`.strip
      log "  Current branch: #{current_branch}"

      # Create new branch
      branch_name = "chore/migrate-to-bug-tracker-gem"
      log "  Creating branch: #{branch_name}"

      if system("git checkout -b #{branch_name} 2>&1")
        log "  ✓ Branch created"
      else
        log "  ❌ ERROR: Failed to create branch. Skipping."
        system("git checkout #{current_branch}")
        return
      end

      begin
        # Remove local bug_tracker and base_error files
        files_to_remove = find_files_to_remove
        files_to_remove.each do |file|
          log "  Removing: #{file}"
          FileUtils.rm_f(file)
        end

        # Update Gemfile
        update_gemfile

        # Update BaseError references
        update_base_error_references

        # Run bundle install
        log "  Running bundle install..."
        if system("bundle install 2>&1 > /dev/null")
          log "  ✓ Bundle install successful"
        else
          log "  ❌ ERROR: Bundle install failed"
          system("git checkout #{current_branch}")
          system("git branch -D #{branch_name}")
          return
        end

        # Commit changes
        log "  Committing changes..."
        system("git add -A")

        commit_message = <<~MSG
          Migrate to BugTracker gem

          - Remove local bug_tracker.rb implementation
          - Remove local base_error.rb implementation
          - Add bug_tracker gem from GitHub
          - Update BaseError references to BugTracker::BaseError

          The BugTracker gem provides:
          - Unified error tracking across all projects
          - Bug fix for extra_context handling
          - Extensible adapter pattern
          - Zero-config setup with smart defaults
        MSG

        if system("git commit -m #{commit_message.shellescape}")
          log "  ✓ Changes committed"
        else
          log "  ❌ ERROR: Commit failed"
          system("git checkout #{current_branch}")
          system("git branch -D #{branch_name}")
          return
        end

        # Push branch
        log "  Pushing branch to remote..."
        if system("git push -u origin #{branch_name} 2>&1")
          log "  ✓ Branch pushed"
          log "  ✅ Migration successful!"
          log "  Next steps:"
          log "    1. Review changes: git diff main..#{branch_name}"
          log "    2. Create PR on GitHub"
          log "    3. Run tests in CI"
          log "    4. Deploy to staging and verify"
        else
          log "  ⚠️  Warning: Failed to push branch (you may not have remote set up)"
          log "  ✅ Migration successful locally!"
          log "  Next steps:"
          log "    1. Review changes: git diff #{current_branch}..#{branch_name}"
          log "    2. Push manually: git push -u origin #{branch_name}"
          log "    3. Create PR on GitHub"
        end

      rescue => e
        log "  ❌ ERROR: #{e.message}"
        log "  Rolling back..."
        system("git checkout #{current_branch}")
        system("git branch -D #{branch_name}")
      end
    end
  end

  def find_files_to_remove
    files = []

    bug_tracker_paths = [
      'app/models/bug_tracker.rb',
      'app/services/bug_tracker.rb',
      'lib/bug_tracker.rb'
    ]

    base_error_paths = [
      'app/models/base_error.rb',
      'lib/base_error.rb'
    ]

    (bug_tracker_paths + base_error_paths).each do |path|
      files << path if File.exist?(path)
    end

    files
  end

  def find_base_error_references
    # Find all Ruby files that reference BaseError (but not BugTracker::BaseError)
    files = []

    Dir.glob('**/*.rb').each do |file|
      next if file.include?('vendor/')
      next if file.include?('node_modules/')

      content = File.read(file)
      # Match BaseError but not BugTracker::BaseError or "class BaseError"
      if content.match?(/(?<!BugTracker::)(?<!class )BaseError(?!.*<)/)
        files << file
      end
    end

    files
  end

  def update_gemfile
    gemfile_path = 'Gemfile'
    return unless File.exist?(gemfile_path)

    content = File.read(gemfile_path)

    if content.include?("gem 'bug_tracker'")
      log "  Gemfile already has bug_tracker gem"
      return
    end

    # Add gem after sentry-ruby if it exists, otherwise at the end
    gem_line = "gem 'bug_tracker', git: '#{GEM_REPO_URL}'\n"

    if content.include?("gem 'sentry-ruby'")
      # Add after sentry-ruby
      content.sub!(/gem ['"]sentry-ruby['"].*\n/) { |m| "#{m}#{gem_line}" }
    else
      # Add at the end
      content += "\n#{gem_line}"
    end

    File.write(gemfile_path, content)
    log "  ✓ Updated Gemfile"
  end

  def update_base_error_references
    files = find_base_error_references

    files.each do |file|
      content = File.read(file)
      original = content.dup

      # Replace class definitions: class FooError < BaseError
      content.gsub!(/class (\w+) < BaseError/, 'class \1 < BugTracker::BaseError')

      # Replace constant references but not class definitions
      content.gsub!(/(?<!class )(?<!BugTracker::)BaseError(?!\s*<)/, 'BugTracker::BaseError')

      if content != original
        File.write(file, content)
        log "  ✓ Updated BaseError references in #{file}"
      end
    end
  end

  def confirm_migration
    print "\nThis will modify #{projects_to_migrate.size} projects. Continue? (y/N): "
    response = $stdin.gets.strip.downcase

    unless response == 'y' || response == 'yes'
      log "Migration cancelled by user"
      exit 0
    end

    log ""
  end

  def print_summary
    log "\n" + "=" * 80
    log "Migration Complete"
    log "=" * 80
    log "Log file: #{log_file}"
    log ""

    unless dry_run
      log "Next steps for each project:"
      log "  1. Review the changes in the branch"
      log "  2. Create a Pull Request"
      log "  3. Run tests locally: bundle exec rspec"
      log "  4. Deploy to staging and verify Sentry integration"
      log "  5. Merge PR after approval"
    end
  end
end

# Parse command line options
options = { dry_run: false }

OptionParser.new do |opts|
  opts.banner = "Usage: migrate_projects.rb [options]"

  opts.on("--dry-run", "Preview changes without making modifications") do
    options[:dry_run] = true
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end
end.parse!

# Run migration
migrator = ProjectMigrator.new(dry_run: options[:dry_run])
migrator.run
