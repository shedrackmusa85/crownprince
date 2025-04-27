# frozen_string_literal: true

# Helper functions at the top level
def record_all_cassettes(cassette_dir)
  # Re-record all cassettes
  FileUtils.rm_rf(cassette_dir)
  FileUtils.mkdir_p(cassette_dir)

  puts 'Recording cassettes for all providers...'
  run_tests
  puts 'Done recording. Please review the new cassettes.'
end

def record_for_providers(providers, cassette_dir) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
  # Get the list of available providers from RubyLLM itself
  all_providers = RubyLLM::Provider.providers.keys.map(&:to_s)

  # Check for valid providers
  if providers.empty?
    puts "Please specify providers or 'all'. Example: rake vcr:record[openai,anthropic]"
    puts "Available providers: #{all_providers.join(', ')}"
    return
  end

  invalid_providers = providers - all_providers
  if invalid_providers.any?
    puts "Invalid providers: #{invalid_providers.join(', ')}"
    puts "Available providers: #{all_providers.join(', ')}"
    return
  end

  # Find and delete matching cassettes
  cassettes_to_delete = find_matching_cassettes(cassette_dir, providers)

  if cassettes_to_delete.empty?
    puts 'No cassettes found for the specified providers.'
    puts 'Running tests to record new cassettes...'
  else
    delete_cassettes(cassettes_to_delete)
    puts "\nRunning tests to record new cassettes..."
  end

  run_tests

  puts "\nDone recording cassettes for #{providers.join(', ')}."
  puts 'Please review the updated cassettes for sensitive information.'
end

def find_matching_cassettes(dir, providers) # rubocop:disable Metrics/MethodLength
  cassettes = []

  Dir.glob("#{dir}/**/*.yml").each do |file|
    basename = File.basename(file)

    # Precise matching to avoid cross-provider confusion
    providers.each do |provider|
      # Match only exact provider prefixes
      next unless basename =~ /^[^_]*_#{provider}_/ || # For first section like "chat_openai_"
                  basename =~ /_#{provider}_[^_]+_/    # For middle sections like "_openai_gpt4_"

      cassettes << file
      break
    end
  end

  cassettes
end

def delete_cassettes(cassettes)
  puts "Deleting #{cassettes.size} cassettes for re-recording:"
  cassettes.each do |file|
    puts "  - #{File.basename(file)}"
    File.delete(file)
  end
end

def run_tests
  system('bundle exec rspec') || abort('Tests failed')
end

namespace :vcr do
  desc 'Record VCR cassettes (rake vcr:record[all] or vcr:record[openai,anthropic])'
  task :record, [:providers] do |_, args|
    require 'fileutils'
    require 'ruby_llm'

    providers = (args[:providers] || '').downcase.split(',')
    cassette_dir = 'spec/fixtures/vcr_cassettes'
    FileUtils.mkdir_p(cassette_dir)

    if providers.include?('all')
      record_all_cassettes(cassette_dir)
    else
      record_for_providers(providers, cassette_dir)
    end
  end
end
