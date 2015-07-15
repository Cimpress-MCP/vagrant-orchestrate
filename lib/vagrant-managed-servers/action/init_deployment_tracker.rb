require "log4r"
require "log4r/outputter/deployment_tracker_outputter"

module Vagrant
  module UI
    class Interface
      attr_reader :logger
    end
  end
end

module VagrantPlugins
  module ManagedServers
    module Action
      class InitDeploymentTracker
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_managed_servers::action::init_deployment_tracker")
        end

        def call(env)
          host = env[:tracker_host]
          return unless host
          SwaggerClient::Swagger.configure do |config|
            config.host = host
          end

          if env[:tracker_logging_enabled]
            ui = env[:ui]
            unless ui.logger.outputters.collect(&:name).include?("deployment-tracker")
              # Make sure that we've hooked the global ui logger as well. We should
              # see if we can do this earlier in the process to capture more of the output
              ui.logger.add Log4r::DeploymentTrackerOutputter.new("deployment-tracker")
            end
          end
          @app.call(env)
        end
      end
    end
  end
end
