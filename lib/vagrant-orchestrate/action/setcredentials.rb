module VagrantPlugins
  module Orchestrate
    module Action
      class SetCredentials
        def initialize(app, _env)
          @app = app
        end

        # rubocop:disable Metrics/AbcSize
        def call(env)
          @machine = env[:machine]

          if @machine.config.orchestrate.credentials
            @ui = env[:ui]
            config_creds = @machine.config.orchestrate.credentials
            (username, password) = retrieve_creds(config_creds)

            # Apply the credentials to the machine info, or back out if we were unable to procure them.
            if username && password
              apply_creds(username, password)
            else
              @ui.warn <<-WARNING
Vagrant-orchestrate could not gather credentials for machine #{@machine.name}. \
Continuing with default credentials."
              WARNING
            end
          end

          @app.call env
        end

        def retrieve_creds(config_creds)
          # Use environment variable overrides, or else what was provided in the config file
          config_creds.username = ENV["VAGRANT_ORCHESTRATE_USERNAME"] || config_creds.username
          config_creds.password = ENV["VAGRANT_ORCHESTRATE_PASSWORD"] || config_creds.password

          # Use credentials file to any username or password that is still undiscovered
          check_creds_file(config_creds) unless config_creds.username && config_creds.password

          # Only prompt if allowed by config
          if config_creds.prompt
            config_creds.username ||= prompt_username
            config_creds.password ||= prompt_password
          end

          [config_creds.username, config_creds.password]
        end

        def apply_creds(username, password)
          configs = [@machine.config.winrm, @machine.config.ssh]
          configs.each do |config|
            next unless config
            config.username = username
            config.password = password
          end
        end

        def prompt_username
          default = ENV["USERNAME"]
          default ||= ENV["USER"]
          username = @ui.ask("username? [#{default}] ")
          username = default if username.empty?
          username
        end

        def prompt_password
          @ui.ask("password? ", echo: false)
        end

        def check_creds_file(config_creds)
          file_path = config_creds.file_path
          return unless file_path
          unless File.exist?(file_path)
            @ui.info "Credential file not found at #{file_path}. Prompting user for credentials."
            return
          end
          begin
            creds_yaml = YAML.load(File.read(file_path))
            config_creds.password ||= creds_yaml[:password] || creds_yaml["password"]
            config_creds.username ||= creds_yaml[:username] || creds_yaml["username"]
          rescue
            @ui.warn "Credentials file at #{file_path} was not valid YAML. Prompting user for credentials."
          end
        end
      end
    end
  end
end
