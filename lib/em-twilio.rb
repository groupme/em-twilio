require "eventmachine"
require "em-http-request"
require "logger"
require "uuid"
require "em-twilio/sms"

$uuid ||= UUID.new

module EventMachine
  module Twilio
    class TwilioError < StandardError;end

    class RequestError < TwilioError;end
    class UnauthorizedError < TwilioError;end
    class ServerError < TwilioError;end
    class ServiceUnavailableError < TwilioError;end
    class MissingCredentialsError < TwilioError;end

    class NetworkError < TwilioError;end
    class TimeoutError < NetworkError;end

    class << self
      def send_sms(to, from, text)
        check_credentials
        SMS.new(to, from, text).deliver
      end

      def authenticate(account_sid, token)
        @account_sid, @token = account_sid, token
      end

      def account_sid
        @account_sid
      end

      def token
        @token
      end

      def logger
        @logger ||= Logger.new(STDOUT)
      end

      def logger=(new_logger)
        @logger = new_logger
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
