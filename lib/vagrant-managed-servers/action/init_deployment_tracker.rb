require "log4r"

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
          @app.call(env)
        end
      end
    end
  end
end
