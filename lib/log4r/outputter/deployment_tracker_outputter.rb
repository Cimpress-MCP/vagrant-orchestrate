require "log4r/outputter/outputter"
require "time"

module Log4r
  class DeploymentTrackerOutputter < Outputter
    def initialize(name, hash = {})
      super(name, hash)
      @logger = Log4r::Logger.new("vagrant_orchestrate::log4r::deployment_tracker_outputter")
    end

    private

    def canonical_log(event)
      data = {}
      data["type"] = event.fullname
      data["timestamp"] = Time.now.getutc.iso8601
      data["level"] = LNAMES[event.level]
      data["message"] = event.data

      begin
        id = VagrantPlugins::Orchestrate::DEPLOYMENT_ID
        DeploymentTrackerClient::DefaultApi.post_logs(id, [data])
      rescue
        @logger.warn "Unable to send log messages to deployment-tracker"
      end
    end
  end
end
