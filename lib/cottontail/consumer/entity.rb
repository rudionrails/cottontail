module Cottontail #:nodoc:
  module Consumer #:nodoc:
    class Entity #:nodoc:
      include Comparable

      VALID_KEYS = [:exchange, :queue, :route]

      def initialize(options = {}, &block)
        @options = options.keep_if { |k, _| VALID_KEYS.include?(k) }
        @block = block
      end

      def matches?(key, value)
        [value, '', :any].include? option(key)
      end

      def option(key)
        @options.fetch(key, '')
      end

      def call(*args)
        @block.call(*args)
      end

      protected

      def <=>(other)
        comparables <=> other.comparables
      end

      def comparables
        VALID_KEYS.map { |key| option(key) }
        # @options.values_at(*VALID_OPTIONS)
      end
    end
  end
end
