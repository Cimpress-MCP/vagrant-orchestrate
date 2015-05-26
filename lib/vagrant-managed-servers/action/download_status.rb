require "log4r"

module VagrantPlugins
  module ManagedServers
    module Action
      class DownloadStatus
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_managed_servers::action::print_status")
        end

        def call(env)
          download_status(env[:machine], env[:local_file_path], env[:remote_file_path], env[:ui])

          @app.call(env)
        end

        def download_status(machine, local, remote, ui)
          machine.communicate.wait_for_ready(5)
          @logger.debug("Downloading orchestrate status for #{machine.name}")
          ui.info("Downloading orchestrate status from #{remote}")
          @logger.debug("  remote file: #{remote}")
          @logger.debug("  local file: #{local}")
          machine.communicate.download(remote, local)
          content = File.read(local)
          @logger.debug("File content:")
          @logger.debug(content)
          status = JSON.parse(content)
          ENV["VAGRANT_ORCHESTRATE_STATUS"] += machine.name.to_s + "   " + status["last_sync"] + \
                                               "  " + status["ref"] + "  " + status["user"] + "\n"
        rescue => ex
          ui.warn("Error downloading status for #{machine.name}.")
          ui.warn(ex.message)
          ENV["VAGRANT_ORCHESTRATE_STATUS"] += machine.name.to_s + "   Status unavailable.\n"
        end
      end
    end
  end
end
