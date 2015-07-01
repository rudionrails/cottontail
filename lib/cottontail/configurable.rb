require 'active_support/core_ext/module/delegation'
require 'active_support/concern'

module Cottontail #:nodoc:
  module Configurable #:nodoc:
    extend ActiveSupport::Concern

    module ClassMethods #:nodoc:
      delegate :set, :get, to: :config

      def config
        return @__config__ if defined?(@__config__)

        @__config__ =
          if respond_to?(:superclass) && superclass.respond_to?(:config)
            superclass.config.inheritable_copy
          else
            # create a new "anonymous" class that will host the compiled
            # reader methods
            Class.new(Configuration).new
          end
      end

      def configure
        yield config
      end
    end

    def config
      self.class.config
    end

    private

    class Configuration #:nodoc:
      def initialize
        @settings = {}
      end

      # Set a configuration option.
      #
      # @example
      #   set :logger, Yell.new($stdout)
      #   set :logger, -> { Yell.new($stdout) }
      def set(key, value)
        @settings[key] = value # value.is_a?(Proc) ? value : -> { value }
      end

      # Get a configuration option. It will be evalued of the first time
      # of calling.
      #
      # @example
      #   get :logger
      def get(key)
        value = @settings[key]
        value = value.call if value.is_a?(Proc)

        value
      end
    end
  end
end
