require 'spec_helper'

RSpec.describe 'A Cottontail::Consumer (singlequeue, singleconsume)' do
  pending 'RabbitMQ not running' unless rabbitmq_running?

  include_context 'a test consumer'

  let(:message_a) { new_message }

  before do
    consumer_class.session do |worker, bunny|
      channel = bunny.create_channel

      a_queue = channel.queue(message_a.queue, auto_delete: true, durable: false)
      worker.subscribe(a_queue, exclusive: false)
    end
  end

  before do
    consumer.start(false)

    # publish message
    channel = publisher.create_channel
    exchange = channel.default_exchange

    exchange.publish(message_a.payload, routing_key: message_a.queue)
  end

  it 'consumes the message' do
    consumer_wait_until(1)

    messages = consumer.messages
    expect(messages.size).to eq(1)

    a_message = messages.find { |m| m[:delivery_info].consumer.queue.name == message_a.queue }
    expect(a_message[:payload]).to eq(message_a.payload)
  end
end
