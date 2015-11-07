begin
  require 'coveralls'

  Coveralls.wear!
rescue LoadError
  $stderr.puts 'Not running coverage'
end
