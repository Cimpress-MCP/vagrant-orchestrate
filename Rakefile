require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RuboCop::RakeTask.new
RSpec::Core::RakeTask.new(:spec)

task build: ["rubocop:auto_correct", :spec]
task default: :build

desc "Run acceptance tests with vagrant-spec"
task :acceptance do
  puts "Bringing up target servers and syncing with NTP"
  # Spinning up local servers here, which the managed provider will connect to
  # by IP. See the Vagrantfile in the root of the repo for more info.
  system("vagrant up /local/ --no-provision")
  # To ensure the ntp sync happens even if the servers are already up
  system("vagrant provision /local/")
  ENV["VAGRANT_ORCHESTRATE_NO_GUARD_CLEAN"] = "true"
  system("bundle exec vagrant-spec test --components=orchestrate/push orchestrate/prompt orchestrate/status")
  puts "Destroying target servers"
  system("vagrant destroy -f /local/")
end
