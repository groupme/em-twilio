module EventMachine
  module Twilio
    class SMS
      def initialize(to, from, body)
        @to, @from, @body = to, from, body
        @uuid = $uuid.generate
      end

      def deliver
        @start = Time.now.to_f
        @http = EventMachine::HttpRequest.new(sms_url).post(
          :query  => {
            "To"    => @to,
            "From"  => @from,
            "Body"  => @body
          },
          :head => {
            "User-Agent" => "em-twilio #{EM::Twilio::VERSION}"
          }
        )
        @http.callback  { callback }
        @http.errback   { |e| error(e.inspect) }
        @http
      end

      private

      def callback
        code = @http.response_header.status.to_i

        if code == 201
          @http.response =~ /<Sid>(.*)<\/Sid>/
          info("sid=#{$1}")
        else
          @http.response =~ /<Message>(.*)<\/Message>/
          message = $1
          message = @http.response.strip unless message
          error("code=#{code} message='#{message}'")

          case code
          when 400
            raise EM::Twilio::RequestError.new(message)
          when 401
            raise EM::Twilio::UnauthorizedError.new(message)
          when 500
            raise EM::Twilio::ServerError.new(message)
          when 502, 503
            raise EM::Twilio::ServiceUnavailableError.new(message)
          end
        end
      end

      def sms_url
        @sms_url ||= "https://#{EM::Twilio.account_sid}:#{EM::Twilio.token}@api.twilio.com/2010-04-01/Accounts/#{EM::Twilio.account_sid}/SMS/Messages"
      end

      def info(message)
        EM::Twilio.logger.info(log_message(message))
      end

      def error(message)
        EM::Twilio.logger.error(log_message(message))
      end

      def log_message(message)
        elapsed = ((Time.now.to_f - @start) * 1000.0).round # in milliseconds
        "#{message} uuid=#{@uuid} to=#{@to} from=#{@from} time=#{elapsed}ms body='#{@body}'"
      end
    end
  end
end
