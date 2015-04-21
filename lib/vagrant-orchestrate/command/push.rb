require "optparse"
require "vagrant"
require "vagrant-orchestrate/action/setcredentials"
require "vagrant-orchestrate/repo_status"
require_relative "command_mixins"

# Borrowed from http://stackoverflow.com/questions/12374645/splitting-an-array-into-equal-parts-in-ruby
class Array
  def in_groups(num_groups)
    return [] if num_groups == 0
    slice_size = (size / Float(num_groups)).ceil
    each_slice(slice_size).to_a
  end
end

module VagrantPlugins
  module Orchestrate
    module Command
      class Push < Vagrant.plugin("2", :command)
        include Vagrant::Util
        include CommandMixins

        @logger = Log4r::Logger.new("vagrant_orchestrate::command::push")

        # rubocop:disable Metrics/AbcSize, MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def execute
          options = {}
          options[:force] = @env.vagrantfile.config.orchestrate.force_push

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant orchestrate push"
            o.separator ""

            o.on("--reboot", "Reboot a managed server after the provisioning step") do
              options[:reboot] = true
            end

            o.on("--strategy strategy", "The orchestration strategy to use. Default is serial") do |v|
              options[:strategy] = v
            end

            o.on("-f", "--force", "Suppress prompting in between groups") do
              options[:force] = true
            end
          end

          argv = parse_options(opts)
          return unless argv

          guard_clean unless ENV["VAGRANT_ORCHESTRATE_NO_GUARD_CLEAN"]

          machines = filter_unmanaged(argv)
          return 0 if machines.empty?

          retrieve_creds(machines) if @env.vagrantfile.config.orchestrate.credentials

          options[:parallel] = true
          strategy = options[:strategy] || @env.vagrantfile.config.orchestrate.strategy
          @env.ui.info("Pushing to managed servers using #{strategy} strategy.")

          # Handle a couple of them more tricky edges.
          strategy = :serial if machines.size == 1
          strategy = :half_half if strategy.to_sym == :canary_half_half && machines.size == 2

          case strategy.to_sym
          when :serial
            options[:parallel] = false
            result = deploy(options, machines)
          when :parallel
            result = deploy(options, machines)
          when :canary
            # A single canary server and then the rest
            result = deploy(options, machines.take(1), machines.drop(1))
          when :half_half
            # Split into two (almost) equal groups
            groups = split(machines)
            result = deploy(options, groups.first, groups.last)
          when :canary_half_half
            # A single canary and then two equal groups
            canary = machines.take(1)
            groups = split(machines.drop(1))
            result = deploy(options, canary, groups.first, groups.last)
          else
            @env.ui.error("Invalid deployment strategy specified")
            result = false
          end

          return 1 unless result
          0
        end
        # rubocop:enable Metrics/AbcSize, MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        def split(machines)
          groups = machines.in_groups(2)
          # Move an item from the first to second group if they are unbalanced so that
          # the smaller group is pushed to first.
          groups.last.unshift(groups.first.pop) if groups.any? && groups.first.size > groups.last.size
          groups
        end

        # rubocop:disable Metrics/AbcSize, MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def deploy(options, *groups)
          groups.select! { |g| g.size > 0 }
          groups.each_with_index do |machines, index|
            next if machines.empty?
            if groups.size > 1
              @env.ui.info("Orchestrating push to group number #{index + 1} of #{groups.size}.")
              @env.ui.info(" -- Hosts: #{machines.collect { |m| m.name.to_s }.join(',')}")
            end
            ENV["VAGRANT_ORCHESTRATE_COMMAND"] = "PUSH"
            begin
              batchify(machines, :up, options)
              batchify(machines, :provision, options)
              upload_status(File.join(@env.tmp_path, "vagrant_orchestrate_status"), @status.repo, machines)
              batchify(machines, :reload, options) if options[:reboot]
            ensure
              batchify(machines, :destroy, options)
              @logger.debug("Finished orchestrating push to group number #{index + 1} of #{groups.size}.")
              ENV.delete "VAGRANT_ORCHESTRATE_COMMAND"
            end

            # Don't prompt on the last group, that would be annoying
            if index == groups.size - 1 || options[:force]
              @logger.debug("Suppressing prompt because --force specified.") if options[:force]
            else
              return false unless prompt_for_continue
            end
          end
        end
        # rubocop:enable Metrics/AbcSize, MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        def prompt_for_continue
          result = @env.ui.ask("Deployment paused for manual review. Would you like to continue? (y/n) ")
          if result.upcase != "Y"
            @env.ui.info("Deployment push action cancelled by user")
            return false
          end
          true
        end

        def batchify(machines, action, options)
          @env.batch(options[:parallel]) do |batch|
            machines.each do |machine|
              batch.action(machine, action, options)
            end
          end
        end

        def retrieve_creds(machines)
          creds = VagrantPlugins::Orchestrate::Action::SetCredentials.new
          (username, password) = creds.retrieve_creds(@env.vagrantfile.config.orchestrate.credentials, @env.ui)

          # Apply the credentials to the machine info, or back out if we were unable to procure them.
          if username && password
            machines.each do |machine|
              creds.apply_creds(machine, username, password)
            end
          else
            @env.ui.warn "Vagrant-orchestrate could not gather credentials. Continuing with default credentials."
          end
        end

        def guard_clean
          clean? && committed? || abort("ERROR!\nThere are files that need to be committed first.")
        end

        def clean?
          `git diff --exit-code 2>&1`
          $CHILD_STATUS == 0
        end

        def committed?
          `git diff-index --quiet --cached HEAD 2>&1`
          $CHILD_STATUS == 0
        end

        def upload_status(machines)
          status = RepoStatus.new
          source = File.write(File.join(@env.tmp_path, "vagrant_orchestrate_status"), status.to_json)
          machines.each do |machine|
            destination = status.remote_path(machine.vm.communicator)
            parent_folder = File.split(destination)[0]
            machine.communicate.wait_for_ready(5)
            @logger.debug("Ensuring vagrant_orchestrate status directory exists")
            machine.communicate.sudo("mkdir -p #{parent_folder}")
            machine.communicate.sudo("chmod 777 #{parent_folder}")
            @logger.debug("Uploading vagrant_orchestrate status file")
            @logger.debug("  source: #{source}")
            @logger.debug("  dest: #{destination}")
            machine.communicate.upload(source, destination)
            @logger.debug("Setting uploaded file world-writable")
            machine.communicate.sudo("chmod 777 #{destination}")
          end
        end
      end
    end
  end
end
