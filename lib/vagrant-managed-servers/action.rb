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
    end
  end
end
