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

        # Delete a file in a way that works on windows
        def super_delete(filepath)
          # Thanks, Windows. http://alx.github.io/2009/01/27/ruby-wundows-unlink.html
          10.times do
            begin
              File.delete(filepath)
              break
            rescue
              @logger.warn("Unable to delete file #{filepath}")
              sleep 0.05
            end
          end
        end
      end
    end
  end
end
