require "vagrant-orchestrate/action/filtermanaged"

begin
  require "vagrant"
rescue LoadError
  raise "The Vagrant Orchestrate plugin must be run within Vagrant."
end

# This is a sanity check to make sure no one is attempting to install
# this into an early Vagrant version.
if Vagrant::VERSION < "1.6.0"
  fail "The Vagrant Orchestrate plugin is only compatible with Vagrant 1.6+"
end

module VagrantPlugins
  module Orchestrate
    class Plugin < Vagrant.plugin("2")
      name "Orchestrate"
      description <<-DESC
      This plugin installs commands that make pushing changes to vagrant-managed-servers easy.
      DESC

      config "orchestrate" do
        require_relative "config"
        Config
      end

      command(:orchestrate) do
        setup_i18n
        setup_logging

        require_relative "command/root"
        Command::Root
      end

      action_hook(:orchestrate, :machine_action_up) do |hook|
        hook.prepend Action::FilterManaged
      end

      action_hook(:orchestrate, :machine_action_provision) do |hook|
        hook.prepend Action::FilterManaged
      end

      action_hook(:orchestrate, :machine_action_destroy) do |hook|
        hook.prepend Action::FilterManaged
      end

      action_hook(:orchestrate, :machine_action_reload) do |hook|
        hook.prepend Action::FilterManaged
      end

      # This initializes the internationalization strings.
      def self.setup_i18n
        I18n.load_path << File.expand_path("locales/en.yml", Orchestrate.source_root)
        I18n.reload!
      end

      # This sets up our log level to be whatever VAGRANT_LOG is.
      def self.setup_logging
        require "log4r"

        level = nil
        begin
          level = Log4r.const_get(ENV["VAGRANT_LOG"].upcase)
        rescue NameError
          # This means that the logging constant wasn't found,
          # which is fine. We just keep `level` as `nil`. But
          # we tell the user.
          level = nil
        end

        # Some constants, such as "true" resolve to booleans, so the
        # above error checking doesn't catch it. This will check to make
        # sure that the log level is an integer, as Log4r requires.
        level = nil unless level.is_a?(Integer)

        # Set the logging level on all "vagrant" namespaced
        # logs as long as we have a valid level.
        if level
          Log4r::Logger.new("vagrant_orchestrate").tap do |logger|
            logger.outputters = Log4r::Outputter.stderr
            logger.level = level
          end
        end
      end
    end
  end
end
