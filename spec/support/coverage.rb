begin
  require 'coveralls'
  require 'simplecov'

  $stdout.puts 'Running coverage...'
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]

  SimpleCov.start do
    add_filter 'spec'
  end
rescue LoadError
  $stderr.puts 'Not running coverage'
end
