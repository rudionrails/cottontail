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
require 'bunny'

class Worker < Cottontail::Base
  # configure the Bunny client with the default connection (host: "localhost", port: 5672) 
  # and with logging.
  set :client, { :logging => true }

  # Declare default direct exchange which is bound to all queues of the type `topic`
  set :exchange, [ "", { :type => :topic } ]

  # Declare the `test` queue
  set :queue, "test"


  # Consume messages on the routing key: `message.received`.Within the provided block 
  # you have access to seleral methods. See Cottontail::Helpers for more details.
  route "message.received" do
    puts "This is the payload #{payload.inspect}"
  end
end

# The following will start Cottontail right away. You need to be aware that it 
# will enter the Bunny subscribe loop, so it will block the process.
Worker.run
```

To run it, you may start it like the following code example. However, you should use a more sophisticated solution for daemonizing your processes in a production environment. See http://www.ruby-toolbox.com/categories/daemonizing for futher inspiration.

```console
ruby worker.rb &
```

Copyright &copy; 2012 Rudolf Schmidt, released under the MIT license
