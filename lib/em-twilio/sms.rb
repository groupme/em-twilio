module EventMachine
  module Twilio
    class SMS
      LIMIT = 160
      TIMEOUT = 5000

      def initialize(to, from, body)
        @to, @from, @body = to, from, body
        @uuid = $uuid.generate
      end

      def deliver(&block)
        self.class.split(@body).map do |body|
          transmit(body, block)
        end
      end

      def transmit(body, block)
        @start = Time.now.to_f
        @http = EventMachine::HttpRequest.new(sms_url).post(
          :body  => {
            "To"    => @to,
            "From"  => @from,
            "Body"  => body
          },
          :head => {
            "authorization"   => [EM::Twilio.account_sid, EM::Twilio.token],
            "User-Agent"      => "em-twilio #{EM::Twilio::VERSION}"
          }
        )

        @http.callback  { callback(block) }
        @http.errback   { errback(block) }
        @http
      end

      private

      def callback(block)
        code = @http.response_header.status.to_i

        if code == 201
          @http.response =~ /<Sid>(.*)<\/Sid>/
          sid = $1
          info("sid=#{sid}")
          block.call(sid, nil) if block
        else
          @http.response =~ /<Message>(.*)<\/Message>/
          message = $1
          message = @http.response.strip unless message
          error("code=#{code} message='#{message}'")

          error = case code
          when 400
            EM::Twilio::RequestError.new(message)
          when 401
            EM::Twilio::UnauthorizedError.new(message)
          when 500
            EM::Twilio::ServerError.new(message)
          when 502, 503
            EM::Twilio::ServiceUnavailableError.new(message)
          end
          block.call(nil, error) if block
        end
      end

      def errback(block)
        if (Time.now.to_f - @start >= TIMEOUT)
          # em-http-request has no good timeout check
          message = "timeout after #{TIMEOUT}ms"
          error = EM::Twilio::TimeoutError.new(message)
        else
          message = "network error: #{@http.error}"
          error = EM::Twilio::NetworkError.new(message)
        end

        error(message)
        block.call(nil, error) if block
      end

      def sms_url
        @sms_url ||= "https://api.twilio.com/2010-04-01/Accounts/#{EM::Twilio.account_sid}/SMS/Messages"
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

      class << self
        def split(text, chunk_size = LIMIT)
          chunks = []
          chunk = ""
          text.dup.split(/ /).each do |word|
            if word.size > chunk_size
              chunk = truncate(word, chunk_size)
            elsif chunk.size + word.size >= chunk_size
              chunks << chunk.dup unless chunk.blank?
              chunk = word
            else
              chunk += chunk.empty? ? word : " #{word}"
            end
          end
          chunks << chunk
          chunks.reject! { |c| c.strip.empty? }
          chunks
        end

        private

        def truncate(text, size)
          text.dup[0..(size-4)] + "..."
        end
      end
    end
  end
end
