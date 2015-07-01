require 'yell'
require File.dirname(__FILE__) + '/cottontail/configurable'

module Cottontail #:nodoc:
  include Cottontail::Configurable

  set :logger, -> { Yell.new(:stdout, colors: true) }
end

require File.dirname(__FILE__) + '/cottontail/consumer'
