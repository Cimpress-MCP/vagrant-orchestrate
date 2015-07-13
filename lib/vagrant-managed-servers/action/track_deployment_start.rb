require "log4r"
require "vagrant-orchestrate/version"

module VagrantPlugins
  module ManagedServers
    module Action
      class TrackDeploymentStart
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_managed_servers::action::track_deployment_start")
        end

        def call(env)
          track_deployment_start(env[:tracker_host], env[:status], env[:ui], env[:args])
          @app.call(env)
        end

        def track_deployment_start(host, status, ui, args)
          return unless host
          id = VagrantPlugins::Orchestrate::DEPLOYMENT_ID
          ui.info("Deployment being tracked in deployment-tracker with ID: #{id}")
          @logger.debug("Tracking deployment start to #{host}.")
          hostname = `hostname`.chomp
          deployment = {
            deployment_id: id,
            engine: "vagrant_orchestrate",
            engine_version: VagrantPlugins::Orchestrate::VERSION,
            user: status.user, host: hostname,
            environment: status.branch,
            package: status.repo,
            package_url: status.remote_origin_url,
            version: status.ref, arguments: args
          }
          DeploymentTrackerClient::DefaultApi.post_deployment(id, deployment)
        rescue => ex
          ui.warn("There was an error notifying deployment tracker. See error log for details.")
          @logger.warn("Error tracking deployment start for deployment #{id}")
          @logger.warn(ex)
        end
      end
    end
  end
end
