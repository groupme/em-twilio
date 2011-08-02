# Test helper for EM::Twilio
#
# To use this, start by simply requiring this file after EM::Twilio
# has already been loaded
#
#     require "em-twilio"
#     require "em-twilio/test_helper"
#
# This will nullify actual deliveries and instead, push them onto an accessible
# list:
#
#     expect {
#       EM::Twilio.sms(to, from, text)
#     }.to change { EM::Twilio.deliveries.size }.by(1)
#
#     sms = EM::Twilio.deliveries.first
#     sms[:body].should == ...
#
module EventMachine
  module Twilio
    def self.deliveries
      @deliveries ||= []
    end

    SMS.class_eval do
      def deliver
        EM::Twilio.deliveries << {
          :to   => @to,
          :from => @from,
          :body => @body
        }
      end
    end
  end
end
