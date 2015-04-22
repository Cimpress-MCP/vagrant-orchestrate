module VagrantPlugins
  module Orchestrate
    module Command
      module CommandMixins
        # Given an array of vagrant command line args (e.g. the result of calling
        # parse_options), filter out unmanaged servers and provide the resulting list.
        def filter_unmanaged(argv)
          machines = []
          with_target_vms(argv) do |machine|
            if machine.provider_name.to_sym == :managed
              machines << machine
            else
              @logger.debug("Skipping #{machine.name} because it doesn't use the :managed provider")
            end
          end

          if machines.empty?
            @env.ui.info("No servers with :managed provider found. Exiting.")
          end

          machines
        end
      end
    end
  end
end
