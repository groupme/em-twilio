module EventMachine
  module Twilio
    class LogMessage
      def initialize(sms, response)
        @sms, @response = sms, response
      end

      def log
        EM::Twilio.logger.debug(debug)

        if @response.success?
          EM::Twilio.logger.info(message)
        else
          EM::Twilio.logger.error(message)
        end
      end

      private

      def message
        parts = [
          "CODE=#{@response.status}",
          "GUID=#{@response.sid}",
          "TO=#{@sms.to}",
          "FROM=#{@sms.from}",
          "BODY=#{@sms.truncated_body}",
          "TIME=#{@response.duration}"
        ]
        parts << "ERROR=#{@response.error}" unless @response.success?
        parts.join(" ")
      end

      def debug
        "FULL_BODY=#{@sms.body}"
      end
    end
  end
end
