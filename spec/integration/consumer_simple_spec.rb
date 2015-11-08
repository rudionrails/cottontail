require 'spec_helper'

RSpec.describe 'A Cottontail::Consumer instance' do
  pending 'RabbitMQ not running' unless rabbitmq_running?

  let(:payload) { SecureRandom.uuid }
  let(:queue_name) { "cottontail-#{SecureRandom.uuid}" }

  let(:consumer_class) do
    Class.new do
      include Cottontail::Consumer

      set :logger, -> { Yell.new(:null) } # no logging
      attr_accessor :consumable

      def initialize(queue_name)
        super()

        @consumable = OpenStruct.new
        @queue_name = queue_name
      end

      session do |worker, session|
        channel = session.create_channel
        queue = channel.queue(@queue_name, :auto_delete => true, :durable => false)

        subscribe(queue, exclusive: false)
      end

      consume do |delivery_info, properties, payload|
        consumable.delivery_info = delivery_info
        consumable.properties = properties
        consumable.payload = payload
      end
    end
  end

  let(:consumer) { consumer_class.new(queue_name) }
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
    exchange.publish(payload, routing_key: queue_name)
  end

  after do
    publisher.stop
    consumer.stop
  end

  it 'consumes the message' do
    10.times { sleep 0.02 if consumable.payload.nil? }
    expect(consumable.payload).to eq(payload)
  end
end
