require 'spec_helper'

RSpec.describe 'A Cottontail::Consumer instance' do
  pending 'RabbitMQ not running' unless rabbitmq_running?

  let(:rand) { SecureRandom.uuid }
  let(:queue) { "cottontail-test-#{rand}" }
  let(:payload) { 'hello world' }

  let(:consumer) { CottontailTestConsumer.new(queue) }
  let(:consumable) { consumer.consumable }

  let :publisher do
    session = Bunny.new
    session.start
    session
  end

  before do
    # start consumer
    consumer.start(false)

    # publish message
    channel = publisher.create_channel
    exchange = channel.default_exchange
    exchange.publish(payload, routing_key: queue)
  end

  after do
    publisher.stop
    consumer.stop
  end

  it 'consumes the message' do
    5.times { sleep 0.1 if consumable.payload.nil? }
    expect(consumable.payload).to eq(payload)
  end
end
