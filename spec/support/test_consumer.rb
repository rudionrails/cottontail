module Cottontail #:nodoc
  module Test #:nodoc
    class Consumer #:nodoc:
      include Cottontail::Consumer
      set :logger, -> { Yell.new(:null) }

      set_callback :initialize, :after do
        @max_messages = options[:max_messages] || 1
      end

      set_callback :consume, :after do
        stop if stop?
      end

      consume do |delivery_info, properties, payload|
        messages << {
          consumable: :default,
          delivery_info: delivery_info,
          properties: properties,
          payload: payload
        }
      end

      def messages
        @messages ||= []
      end

      def stop?
        messages.count >= @max_messages
      end
    end
  end
end
