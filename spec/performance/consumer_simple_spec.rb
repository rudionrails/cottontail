require 'benchmark'
require 'spec_helper'

RSpec.describe 'A Cottontail::Consumer instance', :performance do
  pending 'RabbitMQ not running' unless rabbitmq_running?

  include_context "a test consumer"

  let(:queue_a) { new_queue }
  let(:max_messages) { 10_000 }

  let(:consumer_options) do
    { max_messages: max_messages }
  end

  before do
    consumer_class.session do |worker, bunny|
      channel = bunny.create_channel

      a_queue = channel.queue(queue_a.name, auto_delete: true, durable: false)
      worker.subscribe(a_queue, exclusive: false)
    end
  end

  before do
    # publish messages
    channel = publisher.create_channel
    exchange = channel.default_exchange

    # we need a queue before publishing to it
    channel.queue(queue_a.name, auto_delete: true, durable: false)

    max_messages.times do
      exchange.publish(queue_a.payload, routing_key: queue_a.name)
    end
  end

  it 'consumes the message' do
    seconds = Benchmark.realtime { consumer.start }
    expect(seconds).to be < 2 # seconds
  end
end
