# Cottontail

This library is a wrapper around the popular AMQP bunny gem. It is inspired by Sinatra to easily consume messages on different routing keys.

[![Gem Version](https://badge.fury.io/rb/cottontail.svg)](https://badge.fury.io/rb/cottontail)
[![Build Status](https://travis-ci.org/rudionrails/cottontail.svg?branch=master)](https://travis-ci.org/rudionrails/cottontail)
[![Code Climate](https://codeclimate.com/github/rudionrails/cottontail/badges/gpa.svg)](https://codeclimate.com/github/rudionrails/cottontail)
[![Coverage Status](https://coveralls.io/repos/rudionrails/cottontail/badge.svg?branch=master&service=github)](https://coveralls.io/github/rudionrails/cottontail?branch=master)

## Installation

System wide:

```console
gem install cottontail
```

Or in your Gemfile:

```ruby
gem 'cottontail'
```

## Usage: Simple consumer

When using this gem, you should already be familiar with RabbitMQ and, idealy, Bunny as it is used internally. Given we place our code into `worker.rb`, we can define a simple class like so:.

```ruby
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
# will enter the Bunny subscribe loop, so it will block the process.
Worker.start
```

To run it, you may start it like the following code example. However, you should use a more sophisticated solution for daemonizing your processes in a production environment. See http://www.ruby-toolbox.com/categories/daemonizing for futher inspiration.

```console
ruby worker.rb &
```

Copyright &copy; Rudolf Schmidt, released under the MIT license
