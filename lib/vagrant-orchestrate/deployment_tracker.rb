module VagrantPlugins
  module Orchestrate
    class DeploymentTracker
      @logger = Log4r::Logger.new("vagrant_orchestrate::command::push")

      def self.init_deployment_tracker(host)
        return unless host
        SwaggerClient::Swagger.configure do |config|
          config.host = host
        end
      end

      def self.track_deployment_start(host, status, ui)
        return unless host
        @logger.debug("Tracking deployment start to #{host}.")
        id = VagrantPlugins::Orchestrate::DEPLOYMENT_ID
        hostname = `hostname`
        deployment = {
          deployment_id: id,
          engine: "vagrant_orchestrate",
          engine_version: VagrantPlugins::Orchestrate::VERSION,
          user: status.user,
          host: hostname,
          environment: status.branch,
          package: status.remote_origin_url || status.repo,
          version: status.ref
        }
        DeploymentTrackerClient::DefaultApi.post_deployment(id, deployment)
      rescue => ex
        ui.warn("There was an error notifying deployment tracker. See error log for details.")
        @logger.warn("Error tracking deployment start for deployment #{id}")
        @logger.warn(ex)
      end

      def self.track_deployment_end(host, start, success, ui)
        return unless host
        @logger.debug("Tracking deployment end to #{host}.")
        id = VagrantPlugins::Orchestrate::DEPLOYMENT_ID
        result = success ? "success" : "failure"
        elapsed_seconds = (Time.now - start).to_i
        deployment = { deployment_id: id,
                       result: result,
                       elapsed_seconds: elapsed_seconds }
        DeploymentTrackerClient::DefaultApi.put_deployment(id, deployment)
      rescue => ex
        ui.warn("There was an error notifying deployment tracker. See error log for details.")
        ui.warn(ex)
        @logger.warn("Error tracking deployment end for deployment #{id}")
        @logger.warn(ex)
      end
    end
  end
end
