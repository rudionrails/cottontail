module Cottontail #:nodoc:
  module Consumer #:nodoc:
    # Holds the collection of entities
    class Collection
      def initialize
        @items = []
      end

      # Pushes entity to the list and sorts it
      def push(entity)
        @items.push(entity).sort!
      end

      # {exchange: 'exchange', queue: 'queue', route: 'route'}
      # {exchange: 'exchange', queue: 'queue', route: :any}
      # {exchange: 'exchange', queue: :any, route: 'route'}
      # {exchange: 'exchange', queue: :any, route: :any}
      # {exchange: :any, queue: 'queue'}
      # {exchange: :any, queue: :any}
      def find(delivery_info, _properties, _payload)
        @items
          .select { |e| e.matches?(:exchange, delivery_info.exchange) }
          .select { |e| e.matches?(:queue, delivery_info.consumer.queue.name) }
          .find { |e| e.matches?(:route, delivery_info.routing_key) }
      end
    end
  end
end
