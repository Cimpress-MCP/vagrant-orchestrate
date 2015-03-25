require "optparse"
require "vagrant"

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

          # Parse the options
          argv = parse_options(opts)
          return unless argv

          machines = []
          with_target_vms(argv) do |machine|
            if machine.provider_name.to_sym == :managed
              machines << machine
            else
              @logger.debug("Skipping #{machine.name.to_s} because it doesn't use the :managed provider")
            end
          end

          if machines.empty?
            @env.ui.info("No servers with :managed provider found. Skipping.")
            return
          end

          # This environment variable is used as a signal to the filtermanaged
          # action so that we don't filter managed commands that are really just
          # the implementation of a push action.

          options[:parallel] = true
          strategy = options[:strategy] || @env.vagrantfile.config.orchestrate.strategy
          @env.ui.info("Pushing to managed servers using #{strategy} strategy.")
          case strategy.to_sym
          when :serial
            options[:parallel] = false
            result = deploy(options, machines)
          when :parallel
            result = deploy(options, machines)
          when :canary
            # A single canary server and then the rest
            result = deploy(options, machines.take(1), machines.drop(1))
          when :blue_green
            # Split into two (almost) equal groups
            groups = machines.in_groups(2)
            result = deploy(options, groups.first, groups.last)
          when :canary_blue_green
            # A single canary and then two equal groups
            canary = machines.take(1)
            groups = machines.drop(1).in_groups(2)
            result = deploy(options, canary, groups.first, groups.last)
          else
            @env.ui.error("Invalid deployment strategy specified")
            result = false
          end

          return 1 unless result
          0
        end
        # rubocop:enable Metrics/AbcSize, MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        def deploy(options, *groups)
          groups.each_with_index do |machines, index|
            @logger.debug("Orchestrating push to group number #{index + 1} of #{groups.size}.")
            @logger.debug(" -- Hosts: #{machines.collect { |m| m.name.to_s }.join(",")}")
            ENV["VAGRANT_ORCHESTRATE_COMMAND"] = "PUSH"
            begin
              batchify(machines, :up, options)
              batchify(machines, :provision, options)
              batchify(machines, :reload, options) if options[:reboot]
              batchify(machines, :destroy, options)
              @logger.debug("Finished orchestrating push to group number #{index + 1} of #{groups.size}.")
            ensure
              ENV.delete "VAGRANT_ORCHESTRATE_COMMAND"
            end

            # Don't prompt on the last group, that would be annoying
            unless index == groups.size - 1 || options[:force]
              return false unless prompt_for_continue
            end
          end
        end

        def prompt_for_continue
          result = @env.ui.ask("Deployment paused for manual review. Would you like to continue? (y/n)")
          if result.upcase != "Y"
            @env.ui.info("Deployment push action by user")
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
      end
    end
  end
end
