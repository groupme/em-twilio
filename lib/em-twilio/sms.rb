require 'em-twilio/response'

module EventMachine
  module Twilio
    class SMS
      LIMIT   = 160   # characters
      TIMEOUT = 5000  # ms

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
        start = Time.now.to_f
        http = EventMachine::HttpRequest.new(sms_url).post(
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

        http.callback do
          response = Response.new(http, start)
          block.call(response)
        end

        http.errback do
          response = Response.new(http, start)
          response.error = if (response.duration >= TIMEOUT) # em-http-request has no good timeout check
            EM::Twilio::TimeoutError.new("timeout after #{TIMEOUT}ms")
          else
            EM::Twilio::NetworkError.new("network error: #{http.error}")
          end

          block.call(response) if block
        end
      end

      private

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
