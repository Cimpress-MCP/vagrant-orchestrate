require "vagrant"

module VagrantPlugins
  module Orchestrate
    class Config < Vagrant.plugin(2, :config)
      attr_accessor :filter_managed_commands

      def initialize
        @filter_managed_commands = UNSET_VALUE
      end

      def finalize!
        @filter_managed_commands = false if @filter_managed_commands == UNSET_VALUE
      end
    end
  end
end
