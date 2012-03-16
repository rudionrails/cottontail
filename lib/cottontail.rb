require 'logger'
require 'bunny'

module Cottontail
  class RouteNotFound < StandardError; end

  module Helpers
    # The last_error is accessable within an error block.
    #
    # last_error will be set once an exception was raise
    attr_reader :last_error

    # A RabbitMQ message retrieved by Bunny usually contains the following information:
    #   header [Qrack::Protocol::Header] The header of the message including size, properties, etc.
    #   payload [String] The message sent through RabbitMQ
    #   delivery_details [Hash] Includes the exchange, routing_key, etc
    #
    # This is the original message from the queue (not be confused with the payload sent via RabitMQ).
    attr_reader :message

    # Accessor to the message's payload
    def payload; message[:payload]; end

    # Accessor to the message's header
    def header; message[:header]; end

    # Accessor to the message's delivery details
    def delivery_details; message[:delivery_details]; end

    # Accessor to the delivery detail's routing key
    def routing_key; delivery_details[:routing_key]; end
  end

  class Base
    include Helpers

    class << self
      attr_reader :routes

      # Conveniently set the client
      def client( *args, &block )
        set :client, args, &block
      end

      # Conveniently set the exchange
      def exchange( *args, &block )
        set :exchange, args, &block
      end

      # Conveniently set the queue
      def queue( *args, &block )
        set :queue, args, &block
      end

      # Set runtime configuration
      #
      # @example
      #   set :logger, Logger.new(STDOUT)
      #   set(:logger) { Logger.new(STDOUT) } # will be called on first usage
      def set( key, value = nil, &block )
        @settings[ key ] = block ? block : value
      end

      # Override the standard subscribe loop
      #
      # @example
      #   subscribe :ack => false do |message|
      #     puts "Received #{message.inspect}"
      #     route! message
      #   end
      def subscribe( options = {}, &block )
        set :subscribe, [ options, compile!("subscribe", &block) ]
      end

      # Defines routing on class level
      #
      # @example
      #   route "message.sent" do
      #     ... stuff to do ...
      #   end
      def route( key, options = {}, &block )
        @routes[key] = [ options, compile!("route_#{key}", &block) ]
      end

      # Define error handlers
      #
      # @example Generic route
      #   error do
      #     puts "an error occured"
      #   end
      #
      # @example Error on specific Exception
      #   error RouteNotFound do
      #     puts "Route not found for #{routing_key.inspect}"
      #   end
      def error( *codes, &block )
        codes << :default if codes.empty? # the default error handling

        compiled = compile!("error_#{codes.join("_")}", &block)
        codes.each { |c| @errors[c] = compiled }
      end

      # Route on class level (handy for testing)
      #
      # @example
      #   route! :payload => "some message", :routing_key => "v2.message.sent"
      def route!( message )
        new.route!( message )
      end


      # Retrieve the settings
      #
      # In case a block was given to a settings, it will be called upon first execution and set
      # as the setting's value.
      def settings( key )
        if @settings[key].is_a? Proc
          @settings[key] = @settings[key].call
        end

        @settings[key]
      end

      # Retrieve the error block for the passed Exception class
      #
      # If no class matches, the default will be returned in case it has been set (else nil).
      def error_for( klass )
        @errors[klass] || @errors[:default]
      end

      # convenience method to start the instance
      def run; new.run; end

      # Reset the class
      def reset!
        @settings = {}

        @errors = {}
        @routes = {}

        # default logger
        set :logger, Logger.new(STDOUT)

        # retry settings
        set :retries, true
        set :delay_on_retry, 2

        # default subscribe loop
        set :subscribe, [{}, proc { |m| route! m }]

        # default bunny options
        client
        exchange  "default"
        queue     "default"
      end


      private

        def inherited( subclass )
          subclass.reset!
          super
        end

        # compiles a given proc to an unbound method to be called later on a different binding
        def compile!( name, &block )
          define_method name, &block
          method = instance_method name
          remove_method name

          block.arity == 0 ? proc { |a,p| method.bind(a).call } : proc { |a,*p| method.bind(a).call(*p) }
        end

    end


    def initialize
      reset!
    end

    # Starts the consumer service and enters the subscribe loop.
    def run
      # establish connection and bind routing keys
      logger.debug "[Cottontail] Connecting to client: #{settings(:client).inspect}"
      @client = Bunny.new( *settings(:client) )
      @client.start

      logger.debug "[Cottontail] Declaring exchange: #{settings(:exchange).inspect}"
      exchange = @client.exchange( *settings(:exchange) )

      logger.debug "[Cottontail] Declaring queue: #{settings(:queue).inspect}"
      queue = @client.queue( *settings(:queue) )

      routes.keys.each do |key| 
        logger.debug "[Cottontail] Binding #{key.inspect}"
        queue.bind( exchange, :key => key )
      end

      # enter the subscribe loop
      subscribe!( queue )
    rescue => e
      @client.stop if @client
      reset!

      logger.error "#{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"

      # raise when no retries are defined
      raise( e, caller ) unless settings(:retries)

      logger.debug "[Cottontail] Going to retry in #{settings(:delay_on_retry)} seconds..."
      sleep settings(:delay_on_retry) if settings(:delay_on_retry)
      retry
    end

    # Performs the routing of the given AMQP message
    #
    # The method will raise an error if no route was found or an exception 
    # was raised within matched routing block.
    def route!( message )
      @message = message

      options, block = routes[routing_key]

      raise Cottontail::RouteNotFound.new(routing_key) if block.nil?
      block.call(self)
    end


    private

      # Retrieve routes
      def routes; self.class.routes; end

      # Retrieve settings
      def settings(key); self.class.settings(key); end

      # Conveniently access the logger
      def logger; settings(:logger); end

      # Reset the instance
      def reset!
        @client = nil

        prepare_client_settings!
      end

      # Handles the subscribe loop on the queue.
      def subscribe!( queue )
        logger.debug "[Cottontail] Entering subscribe loop"

        options, block = settings(:subscribe)
        queue.subscribe( options ) do |m|
          with_error_handling!( m, &block )
        end
      end

      # Gracefully handles the given message.
      #
      # @param [Message] m The RabbitMQ message to be handled
      def with_error_handling!( m, &block )
        block.call(self, m)
      rescue => err
        @last_error = err

        if block = self.class.error_for(err.class)
          block.call(self)
        else
          # if no defined exception handling block could be found, then re-raise
          raise( err, caller )
        end
      ensure
        @last_error = nil # unset error after handling
      end

      # The bunny gem itself is not able to handle multiple hosts - although multiple RabbitMQ instances may run in parralel.
      #
      # You may pass :hosts as option when settings the client in order to cycle through them in case a connection was lost.
      def prepare_client_settings!
        return {} unless options = settings(:client).first

        if hosts = options[:hosts]
          host, port = hosts.shift
          hosts << [host, port]

          options.merge!( :host => host, :port => port )
        end

        options
      end

    public

      # === Perform the initial setup
      reset!

  end
end

