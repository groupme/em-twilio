# Twilio SMS delivery for EventMachine

Need to quickly send a lots of SMS messages? Us too.

## Install

Since development is very active, add this to your Gemfile:

    gem "em-twilio", :git => "git://github.com/groupme/em-twilio.git"

## Usage

    require 'eventmachine'
    require 'em-twilio'
    
    EM::Twilio.authenticate(YOUR_ACCOUNT_SID, YOUR_TOKEN)
    
    EM.run do
      to    = "+12135550000"
      from  = "+13105550000"
      body  = "Hello World"
      
      EM::Twilio.send_sms(to, from, body)
      EM.stop
    end
    
### Splitting

The library will split a given body into chunks of __160 characters__ as best
it can.

__If you do not want to split message, you must split it yourself!__

### Callbacks

You can register callbacks to process the Twilio SID or exceptions:

    EM::Twilio.send_sms(to, from, body) do |sid, error|
      # ...
    end

Here's a list of possible exceptions. See `em-twilio.rb` for more.

    EM::Twilio::Error < StandardError
    
    EM::Twilio::RequestError            < EM::Twilio::Error
    EM::Twilio::UnauthorizedError       < EM::Twilio::Error
    EM::Twilio::ServerError             < EM::Twilio::Error
    EM::Twilio::ServiceUnavailableError < EM::Twilio::Error
    EM::Twilio::MissingCredentialsError < EM::Twilio::Error
    EM::Twilio::NetworkError            < EM::Twilio::Error
    EM::Twilio::TimeoutError            < EM::Twilio::NetworkError
    
## Legal

See LICENSE for details