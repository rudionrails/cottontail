require 'spec_helper'

# check if RabbitMQ is running
def rabbitmq_running?
  session = Bunny.new(ENV['RABBITMQ_URL'])
  session.start

  return true
rescue Bunny::TCPConnectionFailedForAllHosts
  return false
ensure
  session.stop
end

class TestConsumer
  include Cottontail::Consumer

  set :logger, Yell.new(:null)
  attr_accessor :consumable

  session do |worker, session|
    channel = session.create_channel

    exchange = channel.topic('cottontail-spec')
    queue = channel.queue('cottontail-spec')
      .bind(exchange, routing_key: '#')

    worker.subscribe(queue, exclusive: true)
  end

  consume do |delivery_info, properties, payload|
    consumable.delivery_info = delivery_info
    consumable.properties = properties
    consumable.payload = payload
  end
end

RSpec.describe 'A Cottontail::Consumer instance' do
  unless rabbitmq_running?
    pending "RabbitMQ not running"
  end

  let!(:message) { 'hello world' }

  let!(:consumer) { TestConsumer.new }
  let!(:consumable) { OpenStruct.new }

  let(:publisher) do
    session = Bunny.new
    session.start
    session
  end

  before do
    # publish
    channel = publisher.create_channel
    channel.topic('cottontail-spec')
      .publish(message, routing_key: 'cottontail-spec')

    # consume
    consumer.consumable = consumable
    consumer.start(false)
  end

  after do
    publisher.stop
    consumer.stop
  end

  it 'consumes the message' do
    expect(consumable.payload).to eq(message)
  end
end

