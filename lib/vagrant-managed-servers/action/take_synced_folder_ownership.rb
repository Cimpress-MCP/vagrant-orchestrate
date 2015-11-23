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

          @logger.debug "Taking ownership of synced folders"
          machine.config.vm.synced_folders.each do |synced_folder|
            name = synced_folder[0]
            options = synced_folder[1]
            next if options[:disabled]
            options[:owner] ||= machine.ssh_info[:username]
            chown machine, options[:guestpath], options[:owner]
          end

          @logger.debug "Taking ownership of provisioner assets"
          machine.config.vm.provisioners.each do |provisioner|
            owner = machine.ssh_info[:username]
            chown machine, provisioner.config.upload_path, owner if provisioner.type == :shell
            chown machine, provisioner.config.temp_dir, owner if provisioner.type == :puppet
          end
        end

        def chown(machine, path, owner)
          @logger.debug "Taking ownership of #{path}"
          machine.communicate.sudo "chown '#{owner}' -R #{path}"
        end
      end
    end
  end
end
