require 'spec_helper'

RSpec.describe 'A Cottontail::Consumer (multiqueue, multiconsume)' do
  pending 'RabbitMQ not running' unless rabbitmq_running?

  include_context 'a test consumer'

  let(:message_a) { new_message }
  let(:message_b) { new_message }

  before do
    consumer_class.session do |worker, bunny|
      channel = bunny.create_channel

      a_queue = channel.queue(message_a.queue, auto_delete: true, durable: false)
      worker.subscribe(a_queue, exclusive: false)

      b_queue = channel.queue(message_b.queue, auto_delete: true, durable: false)
      worker.subscribe(b_queue, exclusive: false)
    end

    consumer_class.consume(message_a.queue) do |delivery_info, properties, payload|
      messages << {
        consumable: :message_a,
        delivery_info: delivery_info,
        properties: properties,
        payload: payload
      }
    end

    consumer_class.consume(message_b.queue) do |delivery_info, properties, payload|
      messages << {
        consumable: :message_b,
        delivery_info: delivery_info,
        properties: properties,
        payload: payload
      }
    end
  end

  before do
    consumer.start(false)

    # publish message
    channel = publisher.create_channel
    exchange = channel.default_exchange

    exchange.publish(message_a.payload, routing_key: message_a.queue)
    exchange.publish(message_b.payload, routing_key: message_b.queue)
  end

  it 'consumes the message' do
    # wait for received message
    consumer_wait_until(2)

    messages = consumer.messages
    expect(messages.size).to eq(2)

    a_message = messages.find { |m| m[:consumable] == :message_a }
    expect(a_message[:payload]).to eq(message_a.payload)

    b_message = messages.find { |m| m[:consumable] == :message_b }
    expect(b_message[:payload]).to eq(message_b.payload)
  end
end
