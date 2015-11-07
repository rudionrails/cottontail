# check if RabbitMQ is running
def rabbitmq_running?
  session = Bunny.new(ENV['RABBITMQ_URL'])

  begin
    session.start

    return true
  rescue Bunny::TCPConnectionFailedForAllHosts
    return false
  ensure
    session.stop
  end
end
