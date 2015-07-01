require 'active_support/concern'

require File.dirname(__FILE__) + '/configurable'
require File.dirname(__FILE__) + '/consumer/launcher'
require File.dirname(__FILE__) + '/consumer/session'
require File.dirname(__FILE__) + '/consumer/collection'
require File.dirname(__FILE__) + '/consumer/entity'

module Cottontail
  # The Cottontail::Consumer is the module for receiving
  # asynchronous AMQP messages.
  #
  # @example
  #   class Worker
  #     include Cottontail::Consumer
  #
  #     session ENV['RABBITMQ_URL'] do |session, worker|
  #       channel = session.create_channel
  #
  #       queue_a = channel.queue('queue_a', durable: true)
  #       worker.subscribe(queue_a, exclusive: true, ack: false)
  #
  #       queue_b = channel.queue('queue_b', durable: true)
  #       worker.subscribe(queue_b, exclusive: true, ack: false)
  #     end
  #
  #     consume queue: 'queue_b' do |delivery_info, properties, payload|
  #       # do stuff from the queue_b
  #     end
  #
  #     consume do |delivery_info, properties, payload|
  #       # do stuff as fallback
  #     end
  #   end
  module Consumer
    extend ActiveSupport::Concern

    included do
      include Cottontail::Configurable

      # default settings
      set :consumables, -> { Cottontail::Consumer::Collection.new }
      set :session, -> { [nil, -> {}] }
      set :logger, -> { Cottontail.get(:logger) }
    end

    module ClassMethods #:nodoc:
      # Set the Bunny session
      #
      # @example Simple Bunny::Session
      #   session ENV['RABBITMQ_URL'] do |session, worker|
      #     channel = session.create_channel
      #
      #     queue_a = channel.queue('queue_a', durable: true)
      #     worker.subscribe(queue_a, exclusive: true, ack: false)
      #
      #     queue_b = channel.queue('queue_b', durable: true)
      #     worker.subscribe(queue_b, exclusive: true, ack: false)
      #   end
      def session(options = nil, &block)
        set :session, [options, block]
      end

      # Method for consuming messages from the queue
      #
      # When `:any` is provided as parameter, all messages will be routed to
      # this block. When a string is passed as parameter, it will be used as
      # the routing key. You may combine it with additional options such as
      # `:queue` or `:exchange`. Also, you may pass a hash directly as shown
      # in the examples.
      #
      # @example By routing key
      #   consume route: 'message.sent' do |message|
      #     # stuff to do
      #   end
      #
      #   # you can also use a shortcut for this
      #   consume "message.sent" do |message|
      #     # stuff to do
      #   end
      #
      # @example By multiple routing keys
      #   consume route: ['message.sent', 'message.read'] do |message|
      #     # stuff to do
      #   end
      #
      #   # you can also use a shortcut for this
      #   consume ["message.sent", "message.read"] do |message|
      #     # stuff to do
      #   end
      #
      # @example By message type
      #   consume type: 'ChatMessage' do |message|
      #     # stuff to do
      #   end
      #
      # @example By multiple message types
      #   consume type: ['ChatMessage', 'PushMessage'] do |message|
      #     # stuff to do
      #   end
      #
      # @example By queue name
      #   consume queue: 'chats' do |message|
      #   end
      #
      # @example With payload modifiers
      #   payload => JSON
      #
      #   consume Consumable.new
      def consume(route = nil, options = {}, &block)
        options = (route.is_a?(Hash) ? route : { route: route }).merge(options)
        get(:consumables).push Cottontail::Consumer::Entity.new(options, &block)
      end

      # Conveniently start the consumer
      #
      # @example
      # class Worker
      #   include Cottontail::Consumer
      #
      #   # ... configuration ...
      # end
      #
      # Worker.start
      def start(blocking = true)
        new.start(blocking)
      end
    end

    def initialize
      @__launcher__ = Cottontail::Consumer::Launcher.new(self)
      @__session__ = Cottontail::Consumer::Session.new(self)

      logger.debug '[Cottontail] initialized'
    end

    def start(blocking = true)
      logger.info '[Cottontail] starting up'

      @__session__.start
      @__launcher__.start if blocking
    end

    def stop
      logger.info '[Cottontail] shutting down'

      # @__launcher__.stop
      @__session__.stop
    end

    # @private
    def subscribe(queue, options)
      queue.subscribe(options) do |delivery_info, properties, payload|
        consumable = consumables.find(delivery_info, properties, payload)

        if consumable.nil?
          # logger.warn "[Cottontail] Could not consume message"
        else
          consumable.call(delivery_info, properties, payload)
        end
      end
    end

    private

    def consumables
      config.get(:consumables)
    end

    def logger
      config.get(:logger)
    end
  end
end
