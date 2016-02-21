require 'benchmark'
require 'spec_helper'

RSpec.describe 'A Cottontail::Consumer instance', :performance do
  pending 'RabbitMQ not running' unless rabbitmq_running?

  let(:payload) { SecureRandom.uuid }
  let(:max_messages) { 10_000 }
  let(:queue_name) { "cottontail-#{SecureRandom.uuid}" }

  let(:consumer_class) do
    Class.new(Cottontail::Test::Consumer) do
      session do |worker, session|
        channel = session.create_channel
        queue = channel.queue(
          options[:queue_name],
          auto_delete: true,
          durable: false
        )

        subscribe(queue, exclusive: false)
      end
    end
  end

  let :consumer do
    consumer_class.new(
      queue_name: queue_name,
      max_messages: max_messages
    )
  end

  let :publisher do
    session = Bunny.new
    session.start

    session
  end

  before do
    # publish messages
    channel = publisher.create_channel
    channel.queue(queue_name, auto_delete: true, durable: false) # create queue

    exchange = channel.default_exchange
    max_messages.times { exchange.publish(payload, routing_key: queue_name) }
  end

  after do
    publisher.stop
  end

  it 'consumes the message' do
    seconds = Benchmark.realtime { consumer.start }
    expect(seconds).to be < 2 # seconds
  end
end
