# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "cottontail/version"

Gem::Specification.new do |s|
  s.name        = "cottontail"
  s.version     = Cottontail::VERSION
  s.authors     = ["Rudolf Schmidt"]
  s.license     = 'MIT'

  s.homepage    = "http://github.com/rudionrails/cottontail"
  s.summary     = %q{Sinatra inspired wrapper around the AMQP Bunny gem}
  s.description = %q{Convenience wrapper around the AMQP Bunny gem to better handle routing_key specific messages}

  s.rubyforge_project = "cottontail"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "bunny", "~> 2"
  s.add_runtime_dependency "yell", ">= 2", "<= 3"
  s.add_runtime_dependency "activesupport", ">= 3", "<= 4"
end
