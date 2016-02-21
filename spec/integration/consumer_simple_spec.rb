require 'spec_helper'

RSpec.describe 'A Cottontail::Consumer instance' do
  pending 'RabbitMQ not running' unless rabbitmq_running?

  let(:payload) { SecureRandom.uuid }
  let(:queue_name) { "cottontail-#{SecureRandom.uuid}" }

  let(:consumer_class) do
    Class.new(Cottontail::Test::Consumer) do
      session do |worker, bunny|
        channel = bunny.create_channel
        queue = channel.queue(
          options[:queue_name],
          auto_delete: true,
          durable: false
        )

        subscribe(queue, exclusive: false)
      end
    end
  end

  let(:consumer) { consumer_class.new(queue_name: queue_name) }

  let :publisher do
    session = Bunny.new
    session.start

    session
  end

  before do
    consumer.start(false)

    # publish message
    channel = publisher.create_channel
    exchange = channel.default_exchange
    exchange.publish(payload, routing_key: queue_name)
  end

  after do
    publisher.stop
    consumer.stop
  end

  it 'consumes the message' do
    # wait for received message
    10.times { sleep 0.02 if consumer.running? }

    message = consumer.messages.last
    expect(message[:payload]).to eq(payload)
  end
end
