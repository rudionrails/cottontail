require 'active_support/concern'
require 'active_support/core_ext/class/attribute'
require 'active_support/callbacks'

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
  #     session ENV['RABBITMQ_URL'] do |worker, bunny|
  #       channel = bunny.create_channel
  #
  #       queue = channel.queue('', durable: true)
  #       worker.subscribe(queue, exclusive: true, ack: false)
  #     end
  #
  #     consume do |delivery_info, properties, payload|
  #       logger.info payload.inspect
  #     end
  #   end
  #
  # @example More custom worker
  #   class Worker
  #     include Cottontail::Consumer
  #
  #     session ENV['RABBITMQ_URL'] do |worker, bunny|
  #       # You always need a separate channel
  #       channel = bunny.create_channel
  #
  #       # Creates a `topic` exchange ('cottontail-exchange'), binds a
  #       # queue ('cottontail-queue') to it and listens to any possible
  #       # routing key ('#').
  #       exchange = channel.topic('cottontail-exchange')
  #       queue = channel.queue('cottontail-queue', durable: true)
  #         .bind(exchange, routing_key: '#')
  #
  #       # Now you need to subscribe the worker instance to this queue.
  #       worker.subscribe(queue, exclusive: true, ack: false)
  #     end
  #
  #     consume 'custom-route' do |delivery_info, properties, payload|
  #       logger.info "routing_key: 'custom-route' | #{payload.inspect}"
  #     end
  #
  #     consume do |delivery_info, properties, payload|
  #       logger.info "any routing key | #{payload.inspect}"
  #     end
  #   end
  module Consumer
    extend ActiveSupport::Concern

    included do
      include ActiveSupport::Callbacks
      define_callbacks :initialize
      define_callbacks :consume

      include Cottontail::Configurable

      # default config
      set :consumables, Cottontail::Consumer::Collection.new
      set :session, [nil, -> {}]
      set :logger, Cottontail.get(:logger)

      # config for consumer behaviour
      set :raise_on_exception, true
    end

    module ClassMethods #:nodoc:
      # Set the Bunny session.
      #
      # You are required to setup a standard Bunny session as you would
      # when using Bunny directly. This enables you to be configurable to
      # the maximum extend.
      #
      # @example Simple Bunny::Session
      #   session ENV['RABBITMQ_URL'] do |worker, bunny|
      #     channel = bunny.create_channel
      #
      #     queue = channel.queue('MyAwesomeQueue', durable: true)
      #     worker.subscribe(queue, exclusive: true, ack: false)
      #   end
      #
      # @example Subscribe to multiple queues
      #   session ENV['RABBITMQ_URL'] do |worker, bunny|
      #     channel = bunny.create_channel
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
      #   consume route: 'message.sent' do |delivery_info, properties, payload|
      #     # stuff to do
      #   end
      #
      #   # you can also use a shortcut for this
      #   consume "message.sent" do |delivery_info, properties, payload|
      #     # stuff to do
      #   end
      #
      # @example By multiple routing keys
      #   consume route: ['message.sent', 'message.read'] do |delivery_info, properties, payload|
      #     # stuff to do
      #   end
      #
      #   # you can also use a shortcut for this
      #   consume ["message.sent", "message.read"] do |delivery_info, properties, payload|
      #     # stuff to do
      #   end
      #
      # @example Scoped to a specific queue
      #   consume route: 'message.sent', queue: 'chats' do |delivery_info, properties, payload|
      #     # do stuff
      #   end
      #
      # @example By message type (not yet implemented)
      #   consume type: 'ChatMessage' do |delivery_info, properties, payload|
      #     # stuff to do
      #   end
      #
      # @example By multiple message types (not yet implemented)
      #   consume type: ['ChatMessage', 'PushMessage'] do |delivery_info, properties, payload|
      #     # stuff to do
      #   end
      def consume(route = {}, options = {}, &block)
        options =
          if route.is_a?(Hash)
            route
          else
            { route: route }
          end.merge(options)

        get(:consumables).push(
          Cottontail::Consumer::Entity.new(options, &block)
        )
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

    attr_accessor :options

    def initialize(options = {})
      @options = options

      run_callbacks :initialize do
        @__running__ = false

        @__launcher__ = Cottontail::Consumer::Launcher.new(self)
        @__session__ = Cottontail::Consumer::Session.new(self)
      end

      logger.debug '[Cottontail] initialized'
    end

    def start(blocking = true)
      logger.info '[Cottontail] starting up'

      @__session__.start
      @__running__ = true
      @__launcher__.start if blocking
    end

    def stop
      return unless running?

      logger.info '[Cottontail] shutting down'

      @__launcher__.stop
      @__session__.stop
      @__running__ = false
    end

    def running?
      @__running__
    end

    # @private
    def subscribe(queue, options)
      queue.subscribe(options) do |delivery_info, properties, payload|
        consume(delivery_info, properties, payload)
      end
    end

    # @private
    def logger
      config.get(:logger)
    end

    private

    def consume(delivery_info, properties, payload)
      run_callbacks :consume do
        execute(delivery_info, properties, payload)
      end
    rescue => exception
      logger.error exception

      if config.get(:raise_on_exception)
        stop

        raise(exception, caller)
      end
    end

    def execute(delivery_info, properties, payload)
      entity = config.get(:consumables).find(delivery_info, properties, payload)

      if entity.nil?
        logger.warn '[Cottontail] Could not consume message'
      else
        entity.exec(self, delivery_info, properties, payload)
      end
    end
  end
end
