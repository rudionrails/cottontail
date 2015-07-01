require 'bunny'

module Cottontail #:nodoc:
  module Consumer #:nodoc:
    class Session #:nodoc:
      def initialize(consumer)
        @consumer = consumer
        @options, @block = @consumer.config.get(:session)
        @session = nil
      end

      def start
        stop unless @session.nil?

        @session = Bunny.new(@options)
        @session.start

        @block.call(@consumer, @session) if @block
      end

      def stop
        @session.stop if @session.respond_to?(:stop)
        @session = nil
      end
    end
  end
end
