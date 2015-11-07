require 'yell'

require File.dirname(__FILE__) + '/cottontail/configurable'
require File.dirname(__FILE__) + '/cottontail/consumer'

module Cottontail #:nodoc:
  include Cottontail::Configurable

  set :logger, -> { Yell.new(:stdout, colors: true) }
end
