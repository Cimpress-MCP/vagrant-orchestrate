require "json"
require "optparse"
require "vagrant"
require "vagrant-orchestrate/repo_status"
require_relative "command_mixins"

module VagrantPlugins
  module Orchestrate
    module Command
      class Status < Vagrant.plugin("2", :command)
        include Vagrant::Util
        include CommandMixins

        @logger = Log4r::Logger.new("vagrant_orchestrate::command::status")

        def execute
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant orchestrate status"
            o.separator ""
          end

          argv = parse_options(opts)
          return unless argv

          machines = filter_unmanaged(argv)
          return 0 if machines.empty?

          print_status machines
        end

        def print_status(machines)
          # There is some detail output fromt he communicator.download that I
          # don't want to suppress, but I also don't want it to be interspersed
          # with the actual status information. Let's buffer the status output.
          output = []
          @logger.debug("About to download machine status")
          machines.each do |machine|
            output << get_status(RepoStatus.new.remote_path(machine.config.vm.communicator), machine)
          end
          @env.ui.info("Current managed server states:")
          @env.ui.info("")
          output.each do |line|
            @env.ui.info line
          end
        end

        def get_status(remote, machine)
          machine.communicate.wait_for_ready(5)
          local = File.join(@env.tmp_path, "#{machine.name}_status")
          @logger.debug("Downloading orchestrate status for #{machine.name}")
          @logger.debug("  remote file: #{remote}")
          @logger.debug("  local file: #{local}")
          machine.communicate.download(remote, local)
          content = File.read(local)
          @logger.debug("File content:")
          @logger.debug(content)
          status = JSON.parse(content)
          return machine.name.to_s + "   " + status["last_sync"] + "  " + status["ref"] + "  " + status["user"]
        rescue => ex
          @env.ui.warn("Error downloading status for #{machine.name}.")
          @env.ui.warn(ex.message)
          return machine.name.to_s + "   Status unavailable."
        ensure
          File.delete(local) if File.exist?(local)
        end
      end
    end
  end
end
