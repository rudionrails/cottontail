class CottontailTestConsumer
  include Cottontail::Consumer

  set :logger, -> { Yell.new(:null) } # no logging
  attr_accessor :consumable

  def initialize(queue = 'cottontail-test-queue')
    super()

    @consumable = OpenStruct.new
    @queue = queue
  end

  session do |worker, session|
    channel = session.create_channel
    queue = channel.queue(@queue, :auto_delete => true, :durable => false)

    worker.subscribe(queue, exclusive: false)
  end

  consume do |delivery_info, properties, payload|
    consumable.delivery_info = delivery_info
    consumable.properties = properties
    consumable.payload = payload
  end
end


