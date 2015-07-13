require "log4r"

module VagrantPlugins
  module ManagedServers
    module Action
      class TrackServerDeploymentStart
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_managed_servers::action::track_server_deployment_start")
        end

        def call(env)
          machine = env[:machine]
          env[:start_times] ||= {}
          env[:start_times][machine.name] = Time.now
          track_deployment_start(machine, env[:ui])
          @app.call(env)
        end

        def track_deployment_start(machine, ui)
          host = machine.config.orchestrate.tracker_host
          return unless host
          @logger.debug("Tracking deployment server start to #{host}.")
          id = VagrantPlugins::Orchestrate::DEPLOYMENT_ID
          server = {
            deployment_id: id,
            hostname: machine.provider_config.server
          }
          DeploymentTrackerClient::DefaultApi.post_server(id, server)
        rescue => ex
          ui.warn("There was an error notifying deployment tracker of server start. Run with --debug for more details.")
          ui.warn(ex.message)
          @logger.warn("Error tracking deployment server start for deployment #{id}")
          @logger.warn(ex)
        end
      end
    end
  end
end
