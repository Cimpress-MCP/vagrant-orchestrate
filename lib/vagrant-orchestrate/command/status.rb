require "json"
require "optparse"
require "vagrant"
require "vagrant-managed-servers/action/download_status"
require_relative "../../vagrant-managed-servers/action"
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
          ENV["VAGRANT_ORCHESTRATE_STATUS"] = ""
          @logger.debug("About to download machine status")
          options = {}
          parallel = true
          local_files = []
          @env.batch(parallel) do |batch|
            machines.each do |machine|
              status = RepoStatus.new(@env.root_path)
              options[:remote_file_path] = status.remote_path(machine.config.vm.communicator)
              options[:local_file_path] = File.join(@env.tmp_path, "#{machine.name}_status")
              local_files << options[:local_file_path]
              batch.action(machine, :download_status, options)
            end
          end
          @env.ui.info("Current managed server states:\n")
          @env.ui.info(ENV["VAGRANT_ORCHESTRATE_STATUS"].split("\n").sort.join("\n"))
        ensure
          local_files.each do |local|
            super_delete(local) if File.exist?(local)
          end
        end
      end
    end
  end
end
