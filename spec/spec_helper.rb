require "rubygems"
require "bundler/setup"
Bundler.require :default, :development

EM::Twilio.logger = Logger.new("/dev/null")

require 'webmock/rspec'

def fixture(name)
  File.new(File.join(File.expand_path(File.dirname(__FILE__)), "fixtures", name))
end

RSpec.configure do |config|
  config.before(:each) do
    EM::Twilio.authenticate(nil, nil) # clear credentials
  end
end
