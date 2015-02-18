require "optparse"
require "vagrant"

module VagrantPlugins
  module Orchestrate
    module Command
      class Push < Vagrant.plugin("2", :command)
        include Vagrant::Util

        def execute
          options = {}

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant orchestrate push"
            o.separator ""

            o.on("--reboot", "Reboot a managed server after the provisioning step") do
              options[:reboot] = true
            end
          end

          # Parse the options
          argv = parse_options(opts)

          with_target_vms(argv) do |machine|
            unless machine.provider_name.to_sym == :managed
              @env.ui.info("Skipping machine #{machine.name}")
              next
            end
            push(machine, options)
          end
        end

        def push(machine, options)
          ENV["VAGRANT_ORCHESTRATE_COMMAND"] = "PUSH"
          begin
            machine.action(:up, options)
            machine.action(:provision, options)
            machine.action(:reload, options) if options[:reboot]
            machine.action(:destroy, options)
          ensure
            ENV.delete "VAGRANT_ORCHESTRATE_COMMAND"
          end
        end
      end
    end
  end
end
