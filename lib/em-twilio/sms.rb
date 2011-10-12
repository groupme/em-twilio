require "em-twilio/response"
require "em-twilio/log_message"

module EventMachine
  module Twilio
    class SMS
      attr_reader :to
      attr_reader :from
      attr_reader :body

      def initialize(to, from, body)
        @to, @from, @body = to, from, body
        @uuid = $uuid.generate
      end

      def deliver(&block)
        start = Time.now.to_f
        http = EventMachine::HttpRequest.new(sms_url).post(
          :body => request_body,
          :head => request_headers
        )

        http.callback do
          response = Response.new(http, start)
          LogMessage.new(self, response).log
          block.call(response) if block_given?
        end

        http.errback do
          response = Response.new(http, start)
          LogMessage.new(self, response).log
          response.error = if (response.duration >= EM::Twilio.timeout) # em-http-request has no good timeout check
            EM::Twilio::TimeoutError.new("timeout after #{EM::Twilio.timeout}ms")
          else
            EM::Twilio::NetworkError.new("network error: #{http.error}")
          end

          block.call(response) if block_given?
        end
      end

      def truncated_body
        @body.gsub(/[\n|'|"]/, '').strip[0..15]
      end

      private

      def sms_url
        @sms_url ||= "https://api.twilio.com/2010-04-01/Accounts/#{EM::Twilio.account_sid}/SMS/Messages"
      end

      def request_body
        {
          "To"    => @to,
          "From"  => @from,
          "Body"  => @body
        }
      end

      def request_headers
        {
          "authorization"   => [EM::Twilio.account_sid, EM::Twilio.token],
          "User-Agent"      => "em-twilio #{EM::Twilio::VERSION}"
        }
      end
    end
  end
end
