require "json"

module VagrantPlugins
  module Orchestrate
    class RepoStatus
      attr_reader :last_sync

      def initialize
        @last_sync = Time.now.utc    # Managed servers could be in different timezones
      end

      def ref
        # Env vars are here only for testing, since vagrant-spec is executed from
        # a temp directory and can't use git to get repository information
        @ref ||= ENV["VAGRANT_ORCHESTRATE_STATUS_TEST_REF"]
        @ref ||= `git log --pretty=format:'%H' --abbrev-commit -1`
        @ref
      end

      def remote_origin_url
        @remote_origin_url ||= ENV["VAGRANT_ORCHESTRATE_STATUS_TEST_REMOTE_ORIGIN_URL"]
        @remote_origin_url ||= `git config --get remote.origin.url`.chomp
        @remote_origin_url
      end

      def repo
        @repo ||= File.basename(remote_origin_url, ".git")
        @repo
      end

      def user
        user = ENV["USER"] || ENV["USERNAME"] || "unknown"
        user = ENV["USERDOMAIN"] + "\\" + user if ENV["USERDOMAIN"]

        @user ||= user
        @user
      end

      def to_json
        contents = {
          repo: repo,
          remote_url: remote_origin_url,
          ref: ref,
          user: user,
          last_sync: last_sync
        }
        JSON.pretty_generate(contents)
      end

      # The path to where this should be stored on a remote machine, inclusive
      # of the file name.
      def remote_path(communicator)
        if communicator == :winrm
          File.join("c:", "programdata", "vagrant_orchestrate", repo)
        else
          File.join("/var", "state", "vagrant_orchestrate", repo)
        end
      end
    end
  end
end
