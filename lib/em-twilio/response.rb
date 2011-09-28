module EventMachine
  module Twilio
    class Response
      attr_accessor :duration
      attr_accessor :error
      attr_accessor :id
      attr_accessor :status

      # Service-specific
      attr_accessor :sid

      def initialize(http = {}, start = nil)
        @duration = compute_duration(start)

        if http.kind_of?(Hash)
          from_hash(http)
        else
          from_http(http)
        end
      end

      def success?
        @status == 201
      end

      private

      def compute_duration(start)
        start && ((Time.now.to_f - start.to_f) * 1000.0).round
      end

      def from_hash(hash)
        @id           = hash[:id] || hash[:sid]
        @sid          = @id
        @status       = hash[:status]
        @error        = hash[:error]
      end

      def from_http(http)
        @status = http.response_header.status.to_i

        if @status == 201
          http.response =~ /<Sid>(.*)<\/Sid>/
          @sid = $1
        else
          http.response =~ /<Message>(.*)<\/Message>/
          message = $1
          message = http.response.strip unless message

          @error = case status
          when 400
            EM::Twilio::RequestError.new(message)
          when 401
            EM::Twilio::UnauthorizedError.new(message)
          when 500
            EM::Twilio::ServerError.new(message)
          when 502, 503
            EM::Twilio::ServiceUnavailableError.new(message)
          end
        end
      end
    end
  end
end
