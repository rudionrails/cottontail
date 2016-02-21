require 'benchmark'
require 'spec_helper'

RSpec.describe 'A Cottontail::Consumer instance', :performance do
  pending 'RabbitMQ not running' unless rabbitmq_running?

  let(:max_messages) { 10_000 }
  let(:queue_name) { "cottontail-#{SecureRandom.uuid}" }

  let(:consumer_class) do
    Class.new do
      include Cottontail::TestConsumer

      def initialize(queue_name, max_messages)
        @queue_name = queue_name
        @max_messages = max_messages

        super()
      end

      session do |worker, session|
        channel = session.create_channel
        queue = channel.queue(@queue_name, auto_delete: true, durable: false)

        subscribe(queue, exclusive: false)
      end

      def stop?
        messages.count >= @max_messages
      end
    end
  end

  let(:consumer) { consumer_class.new(queue_name, max_messages) }
  let(:consumable) { consumer.consumable }

  let :publisher do
    session = Bunny.new
    session.start
    session
  end

  let :total_messages do
    consumer.messages.count
  end

  it 'consumes the message' do
    # publish message
    channel = publisher.create_channel
    channel.queue(queue_name, auto_delete: true, durable: false)

    exchange = channel.default_exchange
    max_messages.times do |num|
      exchange.publish(num.to_s, routing_key: queue_name)
    end
    publisher.stop

    t = Benchmark.realtime { consumer.start }

    puts "#{total_messages} (#{max_messages}) messages took #{t} seconds"
  end
end
