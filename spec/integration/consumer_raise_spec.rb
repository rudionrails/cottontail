require 'spec_helper'

# RSpec.describe 'A Cottontail::Consumer instance' do
#   pending 'RabbitMQ not running' unless rabbitmq_running?

#   class DudeError < StandardError; end

#   let(:payload) { SecureRandom.uuid }
#   let(:queue_name) { "cottontail-#{SecureRandom.uuid}" }

#   let(:consumer_class) do
#     Class.new(Cottontail::Test::Consumer) do
#       set :raise_on_exception, true

#       session do |worker, session|
#         channel = session.create_channel
#         queue = channel.queue(
#           options[:queue_name],
#           auto_delete: true,
#           durable: false
#         )

#         subscribe(queue, exclusive: false)
#       end

#       consume do |delivery_info, properties, payload|
#         raise DudeError, 'something went wrong'
#       end
#     end
#   end

#   let(:consumer) { consumer_class.new(queue_name: queue_name) }

#   let(:publisher) do
#     session = Bunny.new
#     session.start
#     session
#   end

#   after do
#     publisher.stop
#     consumer.stop
#   end

#   it 'consumes the message' do
#     # publish message
#     channel = publisher.create_channel
#     channel.queue(queue_name, auto_delete: true, durable: false)

#     exchange = channel.default_exchange
#     exchange.publish(payload, routing_key: queue_name)

#     begin
#       consumer.start
#     rescue Exception => e
#       byebug
#     end
#     # expect { consumer.start }.to raise_error(DudeError)
#   end
# end
