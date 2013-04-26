require "eventmachine"
require "em-http-request"
require "logger"
require "uuid"
require "em-twilio/sms"
require "em-twilio/splitter"
require "em-twilio/version"

$uuid ||= UUID.new

module EventMachine
  module Twilio
    class Error < StandardError;end
    class RequestError < Error;end
    class UnauthorizedError < Error;end
    class ServerError < Error;end
    class ServiceUnavailableError < Error;end
    class MissingCredentialsError < Error;end

    class NetworkError < Error;end
    class TimeoutError < NetworkError;end

    class << self
      def send_sms(to, from, text, &block)
        check_credentials

        EM::Twilio::Splitter.new(text).each do |body|
          SMS.new(to, from, body).deliver(&block)
        end
      end

      def authenticate(account_sid, token)
        @account_sid, @token = account_sid, token
      end

      def account_sid
        @account_sid
      end

      def logger
        @logger ||= Logger.new(STDOUT)
      end

      def logger=(logger)
        @logger = logger
      end

      # connection timeout in milliseconds
      def timeout
        @timeout ||= 5000
      end

      def timeout=(milliseconds)
        @timeout = milliseconds
      end

      def token
        @token
      end

      private

      def check_credentials
        unless @account_sid && @token
          raise MissingCredentialsError.new("call EM::Twilio.authenticate(account_sid, token) before sending SMS")
        end
      end
    end
  end
end
