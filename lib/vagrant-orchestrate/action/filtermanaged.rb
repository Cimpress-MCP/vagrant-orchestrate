module VagrantPlugins
  module Orchestrate
    module Action
      class FilterManaged
        def initialize(app, _env)
          @app = app
        end

        # rubocop:disable Metrics/AbcSize
        def call(env)
          machine = env[:machine]
          if machine.provider_name == :managed
            if (machine.config.orchestrate.filter_managed_commands) && (ENV["VAGRANT_ORCHESTRATE_COMMAND"] != "PUSH")
              env[:ui].info("Ignoring action #{env[:machine_action]} for managed server #{machine.name}.")
              env[:ui].info("Set `config.orchestrate.filter_managed_commands = false` in your vagrantfile to disable.")
            else
              @app.call(env)
            end
          else
            @app.call(env)
          end
        end
        # rubocop:enable Metrics/AbcSize
      end
    end
  end
end
