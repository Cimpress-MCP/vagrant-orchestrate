require "log4r"

module VagrantPlugins
  module ManagedServers
    module Action
      class TrackDeploymentEnd
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_managed_servers::action::track_deployment_end")
        end

        def call(env)
          track_deployment_end(env[:tracker_host], env[:start_time], env[:success], env[:ui])
          @app.call(env)
        end

        private

        def track_deployment_end(host, start, success, ui)
          return unless host
          @logger.debug("Tracking deployment end to #{host}.")
          id = VagrantPlugins::Orchestrate::DEPLOYMENT_ID
          result = success ? "success" : "failure"
          elapsed_seconds = (Time.now - start).to_i
          deployment = { deployment_id: id,
                         result: result,
                         assert_empty_server_result: true,
                         elapsed_seconds: elapsed_seconds }
          DeploymentTrackerClient::DefaultApi.put_deployment(id, deployment)

          flush_logger ui
        rescue => ex
          ui.warn("There was an error notifying deployment tracker. Run with --debug for more details.")
          @logger.warn("Error tracking deployment end for deployment #{id}")
          @logger.warn(ex)
        end

        # Since log messages are being buffered, there could be some that
        # are buffered up to send, but have yet to be delivered. We'll clear
        # those out now. If there is a problem getting the logs to deployment
        # tracker, we'll just see the 1 warning message
        def flush_logger(ui)
          ui.logger.outputters.each do |outputter|
            outputter.flush if outputter.respond_to?("flush")
          end
        end
      end
    end
  end
end
