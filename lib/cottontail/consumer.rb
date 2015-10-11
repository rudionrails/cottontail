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
  # @example A basic worker
  #   class Worker
  #     include Cottontail::Consumer
  #
  #     session ENV['RABBITMQ_URL'] do |session, worker|
  #       channel = session.create_channel
  #
  #       queue = channel.queue('', durable: true)
  #       worker.subscribe(queue, exclusive: true, ack: false)
  #     end
  #
  #     consume do |delivery_info, properties, payload|
  #       logger.info payload.inspect
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
      # Set the Bunny session.
      #
      # You are required to setup a standard Bunny session as you would
      # when using Bunny directly. This enables you to be configurable to
      # the maximum extend.
      #
      # @example Simple Bunny::Session
      #   session ENV['RABBITMQ_URL'] do |session, worker|
      #     channel = session.create_channel
      #
      #     queue = channel.queue('MyAwesomeQueue', durable: true)
      #     worker.subscribe(queue, exclusive: true, ack: false)
      #   end
      #
      # @example Subscribe to multiple queues
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

      # Method for consuming messages.
      #
      # When `:any` is provided as parameter, all messages will be routed to
      # this block. This is the default.
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
      # @example Scoped to a specific queue
      #   consume route: 'message.sent', queue: 'chats' do |message|
      #     # do stuff
      #   end
      #
      # @example By message type (not yet implemented)
      #   consume type: 'ChatMessage' do |message|
      #     # stuff to do
      #   end
      #
      # @example By multiple message types (not yet implemented)
      #   consume type: ['ChatMessage', 'PushMessage'] do |message|
      #     # stuff to do
      #   end
      #
      def consume(route = nil, options = {}, &block)
        options =
          if route.is_a?(Hash)
            route
          else
            { route: route }
          end.merge(options)

        get(:consumables).push Cottontail::Consumer::Entity.new(options, &block)
      end

      # Conveniently start the consumer
      #
      # @example Since setup
      #   class Worker
      #     include Cottontail::Consumer
      #
      #     # ... configuration ...
      #   end
      #
      #   Worker.start
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
          logger.error '[Cottontail] Could not consume message'
        else
          # consumable.call(delivery_info, properties, payload)
          consumable.attach(self).exec(delivery_info, properties, payload)
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
