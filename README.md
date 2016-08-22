# Cottontail

This library is a wrapper around the popular AMQP bunny gem. It is inspired by Sinatra to easily consume messages on different routing keys.

[![Gem Version](https://badge.fury.io/rb/cottontail.svg)](https://badge.fury.io/rb/cottontail)
[![Build Status](https://travis-ci.org/rudionrails/cottontail.svg?branch=master)](https://travis-ci.org/rudionrails/cottontail)
[![Code Climate](https://codeclimate.com/github/rudionrails/cottontail/badges/gpa.svg)](https://codeclimate.com/github/rudionrails/cottontail)
[![Coverage Status](https://coveralls.io/repos/rudionrails/cottontail/badge.svg?branch=master&service=github)](https://coveralls.io/github/rudionrails/cottontail?branch=master)

## Installation

```ruby
# Gemfile
gem 'cottontail'
```

## Usage: Simple worker

When using this gem, you should already be familiar with RabbitMQ and, ideally, the Bunny gem as it is used internally. Given we place our code into `worker.rb`, we can define a simple class like so:

```ruby
# worker.rb
require 'cottontail'

class Worker
  include Cottontail::Consumer

  session ENV['RABBITMQ_URL'] do |worker, bunny|
    channel = bunny.create_channel

    queue = channel.queue('', durable: true)
    worker.subscribe(queue, exclusive: true, ack: false)
  end

  consume do |delivery_info, properties, payload|
    logger.info payload.inspect
  end
end

# The following will start Cottontail right away. You need to be aware that it
# will enter a subscribe loop, so it will block the process. If you don't want
# that, you can start it non-blocking with `Worker.start(false)`.
Worker.start
```

To run it, you may start it like the following code example. However, you should use a more sophisticated solution for daemonizing your processes in a production environment. See http://www.ruby-toolbox.com/categories/daemonizing for futher inspiration.

```sh
ruby worker.rb &
```

##  Usage: Worker on multiple queues

```ruby
# worker.rb
require 'cottontail'

class Worker
  include Cottontail::Consumer

  session ENV['RABBITMQ_URL'] do |worker, bunny|
    channel = bunny.create_channel

    queue_a = channel.queue('queue_a', durable: true)
    worker.subscribe(queue_a, exclusive: true, ack: false)

    queue_b = channel.queue('queue_b', durable: true)
    worker.subscribe(queue_b, exclusive: true, ack: false)
  end

  consume do |delivery_info, properties, payload|
    logger.info payload.inspect
  end
end
```

## Usage: Worker that consumes multiple messages and handles them differently

You are able to scope `consume` blocks. Like this, you can make a worker class
a lot easier to read. The following options are available: `:exchange`, `:queue`
and `:route`.

If your worker is subscribed to messages, but has no default `consume` block
defined, cottontail's logger will write a error message. However, you can always
include a fallback without any parameters.

```ruby
# worker.rb
require 'cottontail'

class Worker
  include Cottontail::Consumer

  session ENV['RABBITMQ_URL'] do |worker, bunny|
    channel = bunny.create_channel

    # Creates the `topic` exchange 'cottontail-exchange', binds the
    # queue 'cottontail-queue' to it and listens to any possible
    # routing key ('#').
    exchange = channel.topic('cottontail-exchange')
    queue = channel.queue('cottontail-queue', durable: true)
      .bind(exchange, routing_key: '#')

    worker.subscribe(queue, exclusive: true, ack: false)
  end

  # This handles any message with the routing key 'message.sent'
  consume route: 'message.sent' do |delivery_info, properties, payload|
    logger.info 'Received via routing key `message.sent`'
  end

  # This handles any message with the routing key 'message.read'. Also,
  # it uses the short notation (without the hash syntax).
  consume 'message.read' do |delivery_info, properties, payload|
    logger.info 'Received via routing key `message.read`'
  end

  # In case no other consume block matches the criteria, this fill be
  # the fallback to any message coming in.
  consume do |delivery_info, properties, payload|
    logger.info 'Anything else goes here'
  end
end
```

Copyright &copy; Rudolf Schmidt, released under the MIT license
