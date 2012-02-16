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

      # convenience method to start the instance
      def run; new.run; end

      # Reset the class
      def reset!
        @settings = {}

        @errors = {}
        @routes = {}

        # default logger
        set(:logger) { Logger.new(STDOUT) }

        # retry settings
        set(:retries) { true }
        set(:delay_on_retry) { 2 }

        # default subscribe loop
        set :subscribe, {}, proc { |m| route! m }

        # default bunny options
        set :client,    {}
        set :exchange,  "default", :type => :topic
        set :queue,     "default"
      end

      # Set runtime configuration
      #
      # @example
      #   set :host, "localhost"
      #   set(:host) { "localhost" } # will be called on first usage
      def set( key, *args, &block )
        @settings[ key ] = block ? block : args
      end

      # Override the standard subscribe loop
      #
      # @example
      #   subscribe :ack => false do |message|
      #     puts "Received #{message.inspect}"
      #     route! message
      #   end
      def subscribe( options = {}, &block )
        set :subscribe, options, compile!("subscribe", &block)
      end

      # Defines routing on class level
      #
      # @example
      #   route "message.sent" do
      #     ... stuff to do ...
      #   end
      def route( key, &block )
        @routes[key] = compile!("route_#{key}", &block)
      end

      # Define error handlers
      #
      # @example
      #   error RouteNotFound do
      #     puts "Route not found for #{routing_key.inspect}"
      #   end
      def error( *codes, &block )
        codes << :default if codes.empty? # the default error handling

        codes.each { |c| (@errors[c] ||= []) << compile!("error_#{c}", &block) }
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
      def errors( klass )
        @errors[klass] || @errors[:default]
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
      logger.debug "[Cottontail] Connecting to client"
      @client = Bunny.new( *settings(:client) )
      @client.start

      logger.debug "[Cottontail] Declaring exchange"
      exchange = @client.exchange( *settings(:exchange) )

      logger.debug "[Cottontail] Declaring queue"
      queue = @client.queue( *settings(:queue) )

      routes.keys.each do |key| 
        logger.debug "[Cottontail] Binding #{key.inspect} to exchange"
        queue.bind( exchange, :key => key )
      end

      logger.debug "[Cottontail] Entering subscribe loop"
      subscribe! queue
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

    # performs the routing of the given AMQP message.
    def route!( message )
      @message = message
      process!
    rescue => err
      @last_error = err

      if errors(err.class).nil?
        raise( err, caller )
      else
        errors(err.class).each { |block| block.call(self) }
      end
    end


    private

      def process!
        key = @message[:delivery_details][:routing_key]

        raise Cottontail::RouteNotFound.new(key) unless block = routes[key]
        block.call(self)
      end

      def routes; self.class.routes; end

      # Retrieve errors
      def errors(code); self.class.errors(code); end

      # Retrieve settings
      def settings(key); self.class.settings(key); end

      # Conveniently access the logger
      def logger; settings(:logger); end

      # Reset the instance
      def reset!
        @client = nil

        prepare_client_settings!
      end

      def subscribe!( queue )
        options, block = settings(:subscribe)

        queue.subscribe( options ) { |m| block.call(self, m) }
      end

      # The bunny gem itself is not able to handle multiple hosts - although multiple RabbitMQ instances may run in parralel.
      #
      # You may pass :hosts as option when settings the client in order to cycle through them in case a connection was lost.
      def prepare_client_settings!
        return {} unless options = settings(:client) and options = options.first

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

