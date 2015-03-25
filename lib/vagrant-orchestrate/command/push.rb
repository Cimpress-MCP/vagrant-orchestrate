require "optparse"
require "vagrant"

class Array
  def in_groups(num_groups)
    return [] if num_groups == 0
    slice_size = (self.size/Float(num_groups)).ceil
    self.each_slice(slice_size).to_a
  end
end

module VagrantPlugins
  module Orchestrate
    module Command
      class Push < Vagrant.plugin("2", :command)
        include Vagrant::Util

        # rubocop:disable MethodLength
        def execute
          options = {}
          options[:parallel] = false

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant orchestrate push"
            o.separator ""

            o.on("--reboot", "Reboot a managed server after the provisioning step") do
              options[:reboot] = true
            end

            o.on("--strategy STRATEGY", "The deployment strategy to use. Default is serial") do |v|
              options[:strategy] = v
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return unless argv

          machines = []
          with_target_vms(argv) do |machine|
            machines << machine if machine.provider_name.to_sym == :managed
          end

          if machines.empty?
            @env.ui.info("No servers with :managed provider found. Skipping.")
            return
          end

          # This environment variable is used as a signal to the filtermanaged
          # action so that we don't filter managed commands that are really just
          # the implementation of a push action.

          options[:parallel] = true
          strategy = options[:strategy] || machines.first.config.orchestrate.strategy
          @env.ui.info("Pushing to managed servers using #{strategy} strategy.")
          case strategy.to_sym
          when :serial
            options[:parallel] = false
            deploy(options, machines)
          when :parallel
            deploy(options, machines)
          when :canary
            # A single canary server and then the rest
            deploy(options, machines.take(1), machines.drop(1))
          when :blue_green
            # Split into two (almost) equal groups
            groups = machines.in_groups(2)
            deploy(options, groups.first, groups.last)
          when :canary_blue_green
            # A single canary and then two equal groups
            canary = machines.take(1)
            groups = machines.drop(1).in_groups(2)
            deploy(options, canary, groups.first, groups.last)
          else
            @env.ui.error("Invalid deployment strategy specified")
            return 1
          end
        end

        def deploy(options, *groups)
          groups.each_with_index do |machines, index|
            ENV["VAGRANT_ORCHESTRATE_COMMAND"] = "PUSH"
            begin
              # TODO: This could be moved to a composite "push" action, so that
              # we could just batchify one action, rather than trying to do this dance.
              # As written, all of the provisioning would finish before all of the
              # servers rebooted at the same time.
              batchify(machines, :up, options)
              batchify(machines, :provision, options)
              batchify(machines, :reload, options) if options[:reboot]
              batchify(machines, :destroy, options)
            ensure
              ENV.delete "VAGRANT_ORCHESTRATE_COMMAND"
            end

            # TODO: Prompt
          end
        end

        # rubocop:enable MethodLength

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
