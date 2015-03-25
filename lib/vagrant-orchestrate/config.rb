require "vagrant"
require "yaml"

module VagrantPlugins
  module Orchestrate
    class Config < Vagrant.plugin(2, :config)
      attr_accessor :filter_managed_commands
      attr_accessor :strategy
      attr_accessor :force_push
      attr_accessor :credentials

      def initialize
        @filter_managed_commands = UNSET_VALUE
        @strategy = UNSET_VALUE
        @force_push = UNSET_VALUE
        @credentials = Credentials.new
      end

      def credentials
        yield @credentials if block_given?
        @credentials
      end

      # It was a little hard to dig up, but this method gets called on the more general
      # config object, with the more specific config as the argument.
      # https://github.com/mitchellh/vagrant/blob/master/lib/vagrant/config/v2/loader.rb
      def merge(new_config)
        super.tap do |result|
          if new_config.credentials.unset?
            result.credentials = @credentials
          elsif @credentials.unset?
            result.credentials = new_config.credentials
          else
            result.credentials = @credentials.merge(new_config.credentials)
          end
        end
      end

      def finalize!
        @filter_managed_commands = false if @filter_managed_commands == UNSET_VALUE
        @strategy = :serial if @strategy == UNSET_VALUE
        @force_push = false if @force_push == UNSET_VALUE
        @credentials = nil if @credentials.unset?
        @credentials.finalize! if @credentials
      end

      class Credentials
        # Same as Vagrant does to distinguish uninitialized variables and intentional assignments
        # to Ruby's nil, we just have to define ourselves because we're in different scope
        UNSET_VALUE = ::Vagrant::Plugin::V2::Config::UNSET_VALUE

        attr_accessor :prompt
        attr_accessor :file_path
        attr_accessor :username
        attr_accessor :password

        def initialize
          @prompt = UNSET_VALUE
          @file_path = UNSET_VALUE
          @username = UNSET_VALUE
          @password = UNSET_VALUE
          @unset = nil
        end

        def unset?
          @unset || [@prompt, @file_path, @username, @password] == [UNSET_VALUE, UNSET_VALUE, UNSET_VALUE, UNSET_VALUE]
        end

        # Merge needs to be implemented here because this class doesn't get to
        # to extend Vagrant.plugin(2, :config), and it would be pretty surprising
        # if credentials configuration defined at different levels couldn't be merged
        def merge(new_config)
          result = dup
          unless new_config.unset?
            result.prompt = new_config.prompt unless new_config.prompt == UNSET_VALUE
            result.file_path = new_config.file_path unless new_config.file_path == UNSET_VALUE
            result.username = new_config.username unless new_config.username == UNSET_VALUE
            result.password = new_config.password unless new_config.password == UNSET_VALUE
          end
          result
        end

        def finalize!
          @unset = unset?
          @prompt = nil if @prompt == UNSET_VALUE
          @file_path = nil if @file_path == UNSET_VALUE
          @username = nil if @username == UNSET_VALUE
          @password = nil if @password == UNSET_VALUE
        end
      end
    end
  end
end
