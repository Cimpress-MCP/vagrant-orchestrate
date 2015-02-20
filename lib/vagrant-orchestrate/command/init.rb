require "optparse"
require "vagrant"

# rubocop:disable Metrics/ClassLength
module VagrantPlugins
  module Orchestrate
    module Command
      class Init < Vagrant.plugin("2", :command)
        include Vagrant::Util

        DEFAULT_SHELL_PATH = "{{YOUR_SCRIPT_PATH}}"
        DEFAULT_WINRM_USERNAME = "{{YOUR_WINRM_USERNAME}}"
        DEFAULT_WINRM_PASSWORD = "{{YOUR_WINRM_PASSWORD}}"
        DEFAULT_SSH_USERNAME = "{{YOUR_SSH_USERNAME}}"
        DEFAULT_SSH_PRIVATE_KEY_PATH = "{{YOUR_SSH_PRIVATE_KEY_PATH}}"
        DEFAULT_PLUGINS = ["vagrant-managed-servers"]

        # rubocop:disable Metrics/AbcSize, MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def execute
          options = {}

          options[:provisioners] = []
          options[:servers] = []
          options[:environments] = []
          options[:plugins] = DEFAULT_PLUGINS
          options[:puppet_librarian_puppet] = true
          options[:puppet_hiera] = true

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

            o.on("--puppet", "Shorthand for '--provision-with puppet'") do
              options[:provisioners] << "puppet"
            end

            o.on("--[no-]puppet-hiera", "Include templates for hiera. Only with --puppet") do |p|
              options[:puppet_hiera] = p
            end

            o.on("--[no-]puppet-librarian-puppet",
                 "Include a Puppetfile and the vagrant-librarian-puppet plugin. Only with --puppet") do |p|
              options[:puppet_librarian_puppet] = p
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

            o.on("--winrm", "Use the winrm communicator") do
              options[:communicator] = "winrm"
              options[:plugins] << "vagrant-winrm-s"
            end

            o.on("--winrm-username USERNAME", String, "The username for communicating with winrm") do |u|
              options[:winrm_username] = u
            end

            o.on("--winrm-password PASSWORD", String, "The password for communicating with winrm") do |p|
              options[:winrm_password] = p
            end

            o.on("--plugins x,y,z", Array, "A comma separated list of vagrant plugins to be installed") do |p|
              options[:plugins] += p
            end

            o.on("--servers x,y,z", Array, "A CSV list of FQDNs to target managed servers") do |list|
              options[:servers] = list
            end

            o.on("--environments x,y,z", Array, "A CSV list of environments. Takes precedence over --servers") do |list|
              options[:environments] = list
            end

            o.on("-f", "--force", "Force overwriting of files") do
              options[:force] = true
            end
          end

          argv = parse_options(opts)
          return unless argv

          init_puppet options
          init_environments options

          options[:shell_paths] ||= options[:shell_inline] ? [] : [DEFAULT_SHELL_PATH]
          options[:winrm_username] ||= DEFAULT_WINRM_USERNAME
          options[:winrm_password] ||= DEFAULT_WINRM_PASSWORD
          options[:communicator] ||= "ssh"
          options[:ssh_username] ||= DEFAULT_SSH_USERNAME
          options[:ssh_private_key_path] ||= DEFAULT_SSH_PRIVATE_KEY_PATH unless options[:ssh_password]

          contents = TemplateRenderer.render(Orchestrate.source_root.join("templates/vagrant/Vagrantfile"),
                                             provisioners: options[:provisioners],
                                             shell_paths: options[:shell_paths],
                                             shell_inline: options[:shell_inline],
                                             puppet_librarian_puppet: options[:puppet_librarian_puppet],
                                             puppet_hiera: options[:puppet_hiera],
                                             communicator: options[:communicator],
                                             winrm_username: options[:winrm_username],
                                             winrm_password: options[:winrm_password],
                                             ssh_username: options[:ssh_username],
                                             ssh_password: options[:ssh_password],
                                             ssh_private_key_path: options[:ssh_private_key_path],
                                             servers: options[:servers],
                                             environments: options[:environments],
                                             plugins: options[:plugins]
                                             )
          write_file("Vagrantfile", contents, options)
          FileUtils.cp(Orchestrate.source_root.join("templates", "vagrant", "dummy.box"),
                       File.join(@env.cwd, "dummy.box"))
          @env.ui.info(I18n.t("vagrant.commands.init.success"), prefix: false)

          # Success, exit status 0
          0
        end
        # rubocop:enable Metrics/AbcSize, MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        private

        def init_puppet(options)
          return unless options[:provisioners].include? "puppet"

          FileUtils.mkdir_p(File.join(@env.cwd, "puppet"))
          if options[:puppet_librarian_puppet]
            contents = TemplateRenderer.render(Orchestrate.source_root.join("templates/puppet/Puppetfile"))
            write_file File.join("puppet", "Puppetfile"), contents, options
            FileUtils.mkdir_p(File.join(@env.cwd, "puppet", "modules"))
            write_file(File.join(@env.cwd, "puppet", "modules", ".gitignore"), "*", options)
            options[:plugins] << "vagrant-librarian-puppet"
          end

          if options[:puppet_hiera]
            contents = TemplateRenderer.render(Orchestrate.source_root.join("templates/puppet/hiera.yaml"))
            write_file(File.join("puppet", "hiera.yaml"), contents, options)
            FileUtils.mkdir_p(File.join(@env.cwd, "puppet", "hieradata"))
            contents = TemplateRenderer.render(Orchestrate.source_root.join("templates/puppet/hiera/common.yaml"))
            write_file(File.join(@env.cwd, "puppet", "hieradata", "common.yaml"), contents, options)
          end

          FileUtils.mkdir_p(File.join(@env.cwd, "puppet", "manifests"))
          write_file(File.join(@env.cwd, "puppet", "manifests", "default.pp"),
                     "# Your puppet code goes here", options)
        end

        def init_environments(options)
          environments = options[:environments]
          return unless environments.any?

          contents = TemplateRenderer.render(Orchestrate.source_root.join("templates/environment/servers.json"),
                                             environments: environments)
          write_file("servers.json", contents, options)
          @env.ui.info("You've created an environment aware configuration.")
          @env.ui.info("To complete the process you need to do the following: ")
          @env.ui.info(" 1. Add the target servers to servers.json")
          @env.ui.info(" 2. Create a git branch for each environment")
          environments.each do |env|
            @env.ui.info("    git branch #{env}")
          end
        end

        def write_file(filename, contents, options)
          save_path = Pathname.new(filename).expand_path(@env.cwd)
          save_path.delete if save_path.exist? && options[:force]
          fail Vagrant::Errors::VagrantfileExistsError if save_path.exist?

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
# rubocop:enable Metrics/ClassLength
