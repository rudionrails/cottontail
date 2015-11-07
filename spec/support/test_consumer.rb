class CottontailTestConsumer
  include Cottontail::Consumer

  set :logger, -> { Yell.new(:null) } # no logging
  attr_accessor :consumable

  def initialize(topic = 'cottontail-test-topic', queue = 'cottontail-test-queue')
    super()

    @consumable = OpenStruct.new
    @topic = topic
    @queue = queue
  end

  session do |worker, session|
    channel = session.create_channel

    exchange = channel.topic(@topic)
    queue = channel.queue(@queue, :auto_delete => true, :durable => false)
            .bind(exchange, routing_key: '#')

    worker.subscribe(queue, exclusive: true)
  end

  consume do |delivery_info, properties, payload|
    consumable.delivery_info = delivery_info
    consumable.properties = properties
    consumable.payload = payload
  end
end


