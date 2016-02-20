require 'thread'

module Cottontail #:nodoc:
  module Consumer #:nodoc:
    class Launcher #:nodoc:
      SIGNALS = [:QUIT, :TERM, :INT]

      def initialize(consumer)
        @consumer = consumer
        @launcher = nil
      end

      def start
        stop unless @launcher.nil?

        SIGNALS.each do |signal|
          Signal.trap(signal) { Thread.new { @consumer.stop } }
        end

        @launcher = Thread.new { sleep }
        @launcher.join
      end

      def stop
        @launcher.kill if @launcher.respond_to?(:kill)
        @launcher = nil
      end
    end
  end
end
