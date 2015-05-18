# It is useful to be able to call up, provision, reload, and destroy as a single
# unit - it makes things like parallel provisioning more seamless and provides
# a useful action hook for the push command.
module VagrantPlugins
  module ManagedServers
    module Action
      include Vagrant::Action::Builtin

      def self.action_push
        Vagrant::Action::Builder.new.tap do |b|
          b.use action_up
          b.use Call, action_provision do |env, b2|
            if env[:reboot]
              b2.use Call, action_reload do |_env, _b3|
              end
            end
          end
          b.use UploadStatus
          b.use action_destroy
        end
      end

      def self.action_download_status
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use DownloadStatus
        end
      end

      # !!!!!!!!!!!!!!!!!!!!!! "TEMPORARY" PATCH !!!!!!!!!!!!!!!!!!!!!!!
      # I'm adding the SMB support here, while I wait on feedback for
      # https://github.com/tknerr/vagrant-managed-servers/pull/47
      # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      # This action is called when `vagrant provision` is called.
      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use WarnNetworks
          b.use Call, IsLinked do |env, b2|
            if !env[:result]
              b2.use MessageNotLinked
              next
            end

            b2.use Call, IsReachable do |env, b3|
              if !env[:result]
                b3.use MessageNotReachable
                next
              end

              b3.use Provision
              if env[:machine].config.vm.communicator == :winrm
                # Use the builtin vagrant folder sync for Windows target servers.
                # This gives us SMB folder sharing, which is much faster than the
                # WinRM uploader for any non-trivial number of files.
                b3.use Vagrant::Action::Builtin::SyncedFolders
              else
                # Vagrant managed servers custom implementation
                b3.use SyncFolders
              end
            end
          end
        end
      end
    end
  end
end
