module VagrantPlugins
  module Orchestrate
    module Action
      class SetCredentials
        def retrieve_creds(config_creds, ui)
          return unless config_creds

          # Use environment variable overrides, or else what was provided in the config file
          config_creds.username = ENV["VAGRANT_ORCHESTRATE_USERNAME"] || config_creds.username
          config_creds.password = ENV["VAGRANT_ORCHESTRATE_PASSWORD"] || config_creds.password

          # Use credentials file to any username or password that is still undiscovered
          check_creds_file(config_creds, ui) unless config_creds.username && config_creds.password

          config_creds = maybe_prompt(config_creds)

          [config_creds.username, config_creds.password]
        end

        def maybe_prompt(config_creds)
          # Only prompt if allowed by config
          if config_creds.prompt
            config_creds.username ||= prompt_username(ui)
            config_creds.password ||= prompt_password(ui)
          end
          config_creds
        end

        def apply_creds(machine, username, password)
          [machine.config.winrm, machine.config.ssh].each do |config|
            next unless config
            config.username = username
            config.password = password
          end
        end

        def prompt_username(ui)
          default = ENV["USERNAME"]
          default ||= ENV["USER"]
          default = ENV["USERDOMAIN"] + "\\" + default if ENV["USERDOMAIN"]
          username = ui.ask("username? [#{default}] ")
          username = default if username.empty?
          username
        end

        def prompt_password(ui)
          ui.ask("password? ", echo: false)
        end

        def check_creds_file(config_creds, ui)
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
            ui.warn "Credentials file at #{file_path} was not valid YAML. Prompting user for credentials."
          end
        end
      end
    end
  end
end
