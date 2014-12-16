require 'optparse'
require 'vagrant'

module VagrantPlugins
  module Orchestrate
    module Command
      class Init < Vagrant.plugin('2', :command)
        include Vagrant::Util

        def execute
          options = {}

          options[:provisioners] = []

          opts = OptionParser.new do |o|
            o.banner = 'Usage: vagrant orchestrate init [options]'
            o.separator ''
            o.separator 'Options:'
            o.separator ''

            o.on('--provision-with', 'Init only certain provisioners, by type.') do |p|
              options[:provisioners] = p.split(',')
            end

            o.on('--shell', 'Shorthand for --provisioner-with=shell') do
              options[:provisioners] << 'shell'
            end

            o.on('-f', '--force', 'Force overwriting of files') do
              options[:force] = true
            end
          end

          puts "about to parse"
          # Parse the options
          argv = parse_options(opts)
          return if !argv
          puts "finished parsing"

          contents = TemplateRenderer.render(Orchestrate.source_root.join('templates/vagrant/Vagrantfile'),
                                             provisioners: options[:provisioners],
                                             shell_paths: ['zzzzzzzzzzzzzz']
                                             )

          save_path = Pathname.new('Vagrantfile').expand_path(@env.cwd)
          puts "save_path: [#{save_path}]"
          save_path.delete if save_path.exist? && options[:force]
          fail Vagrant::Errors::VagrantfileExistsError if save_path.exist?

          # Write out the contents
          begin
            save_path.open('w+') do |f|
              f.write(contents)
            end
          rescue Errno::EACCES
            raise Vagrant::Errors::VagrantfileWriteError
          end

          @env.ui.info(I18n.t('vagrant.commands.init.success'), prefix: false)

          # Success, exit status 0
          0
        end
      end
    end
  end
end
