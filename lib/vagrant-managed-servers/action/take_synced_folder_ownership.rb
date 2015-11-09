require "log4r"

module VagrantPlugins
  module ManagedServers
    module Action
      class TakeSyncedFolderOwnership
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_managed_servers::action::take_synced_folder_ownership")
        end

        def call(env)
          take_synced_folder_ownership env[:machine], env[:ui]
          @app.call(env)
        end

        def take_synced_folder_ownership(machine, ui)
          return unless machine.config.orchestrate.take_synced_folder_ownership
          ui.info "Taking ownership of all guest synced folders"

          machine.config.vm.synced_folders.each do |synced_folder|
            name = synced_folder[0]
            options = synced_folder[1]
            next if options[:disabled]
            options[:owner] ||= machine.ssh_info[:username]
            @logger.debug "Taking ownership of #{name}"
            @logger.debug options
            machine.communicate.sudo "chown #{options[:owner]} -R #{options[:guestpath]}"
          end
        end
      end
    end
  end
end
