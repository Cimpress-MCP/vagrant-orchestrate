require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RuboCop::RakeTask.new
RSpec::Core::RakeTask.new(:spec)

task build: ["rubocop:auto_correct", :spec]
task default: :build

desc "Run acceptance tests with vagrant-spec"
task :acceptance do
  puts "Brining up target servers"
  system("vagrant up /local/ --no-provision")
  # To ensure the ntp sync happens even if the servers are already up
  system("vagrant provision /local/")
  system("bundle exec vagrant-spec test --components=orchestrate/push orchestrate/prompt")
  puts "Destroying target servers"
  system("vagrant destroy -f /local/")
end
