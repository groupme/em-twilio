# -*- mode: ruby; encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "em-twilio/version"

Gem::Specification.new do |s|
  s.name        = "em-twilio"
  s.version     = EventMachine::Twilio::VERSION
  s.authors     = ["Brandon Keene"]
  s.email       = ["brandon@groupme.com"]
  s.homepage    = "http://www.twilio.com/docs/api/rest/sending-sms"
  s.summary     = %q{Twilio SMS delivery for EventMachine}

  s.rubyforge_project = "em-wpn"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "eventmachine", ">= 1.0.0.beta.3"
  s.add_dependency "em-http-request", ">= 1.0.0.beta.4"
  s.add_dependency "uuid"

  s.add_development_dependency "rspec", "~> 2.6.0"
end
