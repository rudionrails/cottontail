# RSpec.shared_context "a consumer", :shared_context => :metadata do
RSpec.shared_context 'a test consumer' do
  let(:consumer_class) { new_consumer_class }
  let(:consumer_options) { {} }
  let(:consumer) { consumer_class.new(consumer_options) }

  let :publisher do
    session = Bunny.new
    session.start

    session
  end

  after do
    publisher.stop
    consumer.stop
  end

  private

  def consumer_wait_until(count, amount = 10)
    amount.times { consumer.messages.count == count ? break : sleep(0.02) }
  end

  def new_message
    OpenStruct.new(
      queue: "cottontail-queue-#{SecureRandom.uuid}",
      route: "cottontail-route-#{SecureRandom.uuid}",
      payload: SecureRandom.uuid
    )
  end

  def new_consumer_class
    Class.new do
      include Cottontail::Consumer
      set :logger, -> { Yell.new(:null) } # no logging output

      set_callback :consume, :after do
        stop if messages.count >= (options[:max_messages] || 99)
      end

      consume do |delivery_info, properties, payload|
        logger.info payload

        messages << {
          consumable: :default,
          delivery_info: delivery_info,
          properties: properties,
          payload: payload
        }
      end

      # @private
      def messages
        @messages ||= []
      end
    end
  end
end
