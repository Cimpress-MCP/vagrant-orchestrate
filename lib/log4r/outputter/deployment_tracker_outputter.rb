require "log4r/outputter/outputter"
require "time"
require "thread"

module Log4r
  class DeploymentTrackerOutputter < Outputter
    FLUSH_SIZE = 25	 				# Number of messages to queue before a flush happens
    MAX_QUEUE_SIZE = 255		# Maximum number of messages to store before messages are dropped

    def initialize(name, hash = {})
      super(name, hash)
      @logger = Log4r::Logger.new("vagrant_orchestrate::log4r::deployment_tracker_outputter")
      @queue = []
      @lock = Mutex.new
    end

    def flush
      @lock.synchronize do
        DeploymentTrackerClient::DefaultApi.post_logs(VagrantPlugins::Orchestrate::DEPLOYMENT_ID, @queue)
        @queue.clear
      end
    rescue
      @logger.warn "Unable to send log messages to deployment-tracker"
    end

    private

    def canonical_log(event)
      if @queue.size >= MAX_QUEUE_SIZE
        @logger.warn("Deployment Tracker Log Outputter queue size at maximum of #{MAX_QUEUE_SIZE}, dropping message")
        return
      end

      data = {}
      data["type"] = event.fullname
      data["timestamp"] = Time.now.getutc.iso8601
      data["level"] = LNAMES[event.level]
      data["message"] = event.data

      @queue << data

      flush if @queue.size >= FLUSH_SIZE
    end
  end
end
