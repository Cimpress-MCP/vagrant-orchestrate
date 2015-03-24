require "optparse"
require "vagrant"

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

            o.on("--[no-]parallel", "Execution machine provisioning in parallel. Default is false") do |v|
              options[:parallel] = v
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return unless argv

          machines = []
          with_target_vms(argv) do |machine|
            machines << machine if machine.provider_name.to_sym == :managed
          end

          # This environment variable is used as a signal to the filtermanaged
          # action so that we don't filter managed commands that are really just
          # the implementation of a push action.
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
