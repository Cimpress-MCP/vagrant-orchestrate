require 'optparse'

module VagrantPlugins
  module Orchestrate
    module Command
      class Init < Vagrant.plugin("2", :command)
        include Vagrant::Util

        def execute

          options = {}

          options[:provisioners] = []

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant orchestrate init [options]"
            o.separator ""
            o.separator "Options:"
            o.separator ""

            o.on("-b", "--box", String, "Box name") do |b|
              options[:box] = b
            end

            o.on("--shell", "Shorthand for --provisioner-with=shell") do |i|
              options[:provisioners] << 'shell'
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          puts argv

          puts "INIT, sucka"
          puts TemplateRenderer.render(Orchestrate.source_root.join("templates/vagrant/Vagrantfile"),
                                        box_name: argv[0] || "base",
                                        provisioners: options[:provisioners],
                                        shell_paths: ['a']
                                        )
          # Success, exit status 0
          0
        end
      end
    end
  end
end
