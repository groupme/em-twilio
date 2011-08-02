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

### Exceptions

The library raises an error on pretty much every non 201 response code.

It's your responsibility to handle them.

Exceptions __WILL NOT__ stop the reactor. This is up to you.

Here's a list of possible exceptions. See `em-twilio.rb` for more.

    TwilioError < StandardError

    RequestError            < TwilioError
    UnauthorizedError       < TwilioError
    ServerError             < TwilioError
    ServiceUnavailableError < TwilioError
    MissingCredentialsError < TwilioError
    
## Legal

See LICENSE for details