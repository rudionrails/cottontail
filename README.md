# Cottontail

This library is a wrapper around the popular AMQP bunny gem. It is inspired by Sinatra to easily consume messages on different routing keys.

## Installation

System wide:

```console
gem install cottontail
```

Or in your Gemfile:

```ruby
gem 'cottontail'
```

## Usage

When using this gem, you should already be familiar with RabbitMQ and, idealy, Bunny as it's a wrapper around it. Given we place our code into `worker.rb`, we can define a simple class like so:.

```ruby
require 'cottontail'

class Worker
  include Cottontail::Consumer

  session ENV['RABBITMQ_URL'] do |worker, session|
    channel = session.create_channel

    queue_a = channel.queue('queue_a', durable: true)
    worker.subscribe(queue_a, exclusive: true)

    queue_b = channel.queue('queue_b', durable: true)
    worker.subscribe(queue_b, exclusive: true)
  end

  consume queue: 'queue_b' do |delivery_info, properties, payload|
    byebug

    puts "DeliveryInfo\t#{delivery_info.to_hash.keys.inspect}", "",
      "Properties\t#{properties.inspect}", "",
      "Payload\t#{payload.inspect}", ""
  end

  consume do |delivery_info, properties, payload|
    buebug

    puts "DeliveryInfo\t#{delivery_info.to_hash.keys.inspect}", "",
      "Properties\t#{properties.inspect}", "",
      "Payload\t#{payload.inspect}", ""
  end
end

# The following will start Cottontail right away. You need to be aware that it
# will enter the Bunny subscribe loop, so it will block the process.
Worker.start
```

To run it, you may start it like the following code example. However, you should use a more sophisticated solution for daemonizing your processes in a production environment. See http://www.ruby-toolbox.com/categories/daemonizing for futher inspiration.

```console
ruby worker.rb &
```

Copyright &copy; 2012 Rudolf Schmidt, released under the MIT license
