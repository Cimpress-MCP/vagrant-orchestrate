require "log4r"

module VagrantPlugins
  module ManagedServers
    module Action
      class TrackServerDeploymentEnd
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_managed_servers::action::track_server_deployment_end")
        end

        def call(env)
          machine = env[:machine]
          track_deployment_end(machine, env[:ui], env[:start_times][machine.name])
          @app.call(env)
        end

        def track_deployment_end(machine, ui, start_time)
          host = machine.config.orchestrate.tracker_host
          return unless host
          @logger.debug("Tracking deployment server end to #{host}.")
          id = VagrantPlugins::Orchestrate::DEPLOYMENT_ID
          server = {
            deployment_id: id,
            hostname: machine.provider_config.server,
            result: "success",
            elapsed_seconds: (Time.now - start_time).to_i
          }
          DeploymentTrackerClient::DefaultApi.put_server(id, server)
        rescue => ex
          ui.warn("There was an error notifying deployment tracker of server end. See error log for details.")
          ui.warn(ex.message)
          pp ex
          @logger.warn("Error tracking deployment server end for deployment #{id}")
          @logger.warn(ex)
        end
      end
    end
  end
end
