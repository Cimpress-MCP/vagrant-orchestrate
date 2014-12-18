require "optparse"
require "vagrant"

module VagrantPlugins
  module Orchestrate
    module Command
      class Init < Vagrant.plugin("2", :command)
        include Vagrant::Util

        DEFAULT_SHELL_PATH = "{{YOUR_SCRIPT_PATH}}"
        DEFAULT_SHELL_INLINE = "{{YOUR_SCRIPT_COMMAND}}"
        DEFAULT_WINRM_USERNAME = "{{YOUR_WINRM_USERNAME}}"
        DEFAULT_WINRM_PASSWORD = "{{YOUR_WINRM_PASSWORD}}"
        DEFAULT_SSH_USERNAME = "{{YOUR_SSH_USERNAME}}"
        DEFAULT_SSH_PASSWORD = "{{YOUR_SSH_PASSWORD}}"
        DEFAULT_SSH_PRIVATE_KEY_PATH = "{{YOUR_SSH_PRIVATE_KEY_PATH}}"

        # rubocop:disable Metrics/AbcSize, MethodLength
        def execute
          options = {}

          options[:provisioners] = []
          options[:servers] = []
          options[:plugins] = ["vagrant-managed-servers"]

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant orchestrate init [options]"
            o.separator ""
            o.separator "Options:"
            o.separator ""

            o.on("--provision-with x,y,z", Array, "Init only certain provisioners, by type.") do |list|
              options[:provisioners] = list
            end

            o.on("--shell", "Shorthand for --provision-with shell") do
              options[:provisioners] << "shell"
            end

            o.on("--shell-paths x,y,z", Array,
                 "Comma separated list of shell scripts to run on provision. Only with --shell") do |list|
              options[:shell_paths] = list
            end

            o.on("--shell-inline command", String, "Inline script to run. Only with --shell") do |c|
              options[:shell_inline] = c
            end

            o.on("--puppet", "Shorthand for --provisioner-with=puppet") do
              options[:provisioners] << "puppet"
            end

            o.on("--communicator COMMUNICATOR", String, "The communicator to use. ssh (default) or winrm") do |c|
              options[:communicator] = c
            end

            o.on("--ssh-username USERNAME", String, "The username for communicating over ssh") do |u|
              options[:ssh_username] = u
            end

            o.on("--ssh-password PASSWORD", String, "The username for communicating over ssh") do |p|
              options[:ssh_password] = p
            end

            o.on("--ssh-private-key-path PATH", String, "Paths to the private key for communinicating over ssh") do |k|
              options[:ssh_private_key_path] = k
            end

            o.on("--winrm-username USERNAME", String, "The username for communicating with winrm") do |u|
              options[:winrm_username] = u
            end

            o.on("--winrm-password PASSWORD", String, "The password for communicating with winrm") do |p|
              options[:winrm_password] = p
            end

            o.on("--plugins x,y,z", Array, "A comma separated list of vagrant plugins to be installed") do |p|
              options[:plugins] = p
            end

            o.on("--servers x,y,z", Array, "A comma separated list of servers hostnames or IPs to deploy to") do |list|
              options[:servers] = list
            end

            o.on("-f", "--force", "Force overwriting of files") do
              options[:force] = true
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return unless argv

          options[:shell_paths] ||= options[:shell_inline] ? [] : [DEFAULT_SHELL_PATH]
          options[:shell_inline] ||= DEFAULT_SHELL_INLINE
          options[:winrm_username] ||= DEFAULT_WINRM_USERNAME
          options[:winrm_password] ||= DEFAULT_WINRM_PASSWORD
          options[:communicator] ||= "ssh"
          options[:ssh_username] ||= DEFAULT_SSH_USERNAME
          options[:ssh_password] ||= DEFAULT_SSH_PASSWORD unless options[:ssh_private_key_path]
          options[:ssh_private_key_path] ||= DEFAULT_SSH_PRIVATE_KEY_PATH

          contents = TemplateRenderer.render(Orchestrate.source_root.join("templates/vagrant/Vagrantfile"),
                                             provisioners: options[:provisioners],
                                             shell_paths: options[:shell_paths],
                                             shell_inline: options[:shell_inline],
                                             communicator: options[:communicator],
                                             winrm_username: options[:winrm_username],
                                             winrm_password: options[:winrm_password],
                                             ssh_username: options[:ssh_username],
                                             ssh_password: options[:ssh_password],
                                             ssh_private_key_path: options[:ssh_private_key_path],
                                             servers: options[:servers],
                                             plugins: options[:plugins]
                                             )
          write_vagrantfile(contents, options)

          @env.ui.info(I18n.t("vagrant.commands.init.success"), prefix: false)

          # Success, exit status 0
          0
        end
        # rubocop:enable Metrics/AbcSize, MethodLength

        private

        def write_vagrantfile(contents, options)
          save_path = Pathname.new("Vagrantfile").expand_path(@env.cwd)
          save_path.delete if save_path.exist? && options[:force]
          fail Vagrant::Errors::VagrantfileExistsError if save_path.exist?

          # Write out the contents
          begin
            save_path.open("w+") do |f|
              f.write(contents)
            end
          rescue Errno::EACCES
            raise Vagrant::Errors::VagrantfileWriteError
          end
        end
      end
    end
  end
end
