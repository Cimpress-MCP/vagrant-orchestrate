require "log4r"

module VagrantPlugins
  module ManagedServers
    module Action
      class UploadStatus
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_managed_servers::action::upload_status")
        end

        def call(env)
          upload_status(env[:status], env[:machine], env[:ui])

          @app.call(env)
        end

        def upload_status(status, machine, ui)
          source = status.local_path
          destination = status.remote_path(machine.config.vm.communicator)
          parent_folder = File.split(destination)[0]
          machine.communicate.wait_for_ready(5)
          @logger.debug("Ensuring vagrant_orchestrate status directory exists")
          machine.communicate.sudo("mkdir -p #{parent_folder}")
          machine.communicate.sudo("chmod 777 #{parent_folder}")
          ui.info("Uploading vagrant orchestrate status")
          @logger.debug("Uploading vagrant_orchestrate status")
          @logger.debug("  source: #{source}")
          @logger.debug("  dest: #{destination}")
          machine.communicate.upload(source, destination)
          @logger.debug("Setting uploaded file world-writable")
          machine.communicate.sudo("chmod 777 #{destination}")
        rescue => ex
          @logger.error(ex)
          ui.warn("An error occurred when trying to upload status to #{machine.name}. Continuing")
          ui.warn(ex.message)
        end
      end
    end
  end
end
