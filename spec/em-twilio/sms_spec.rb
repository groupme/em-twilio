require 'spec_helper'

describe EventMachine::Twilio::SMS do
  describe "#deliver" do
    before do
      EM::Twilio.authenticate("account_sid", "token")
    end

    describe "201 Created" do
      before do
        url = "https://account_sid:token@api.twilio.com/2010-04-01/Accounts/account_sid/SMS/Messages"
        stub_request(:post, url).with(
          :query => {
            "To"    => "+12135550000",
            "From"  => "+13105550000",
            "Body"  => "Hello"
          },
          :headers => {
            "User-Agent" => "em-twilio #{EM::Twilio::VERSION}"
          }
        ).to_return(fixture("created.txt"))
      end

      it "logs SID info" do
        sms = EM::Twilio::SMS.new("+12135550000", "+13105550000", "Hello")
        sms.should_receive(:info).with(
          "sid=SM805624cca3b410ad489c9e6dcf116b87"
        )

        EM.run_block { sms.deliver }
      end

      it "sends to Twilio" do
        sms = EM::Twilio::SMS.new("+12135550000", "+13105550000", "Hello")

        EM.run_block { @http = sms.deliver }
        @http.response_header.status.should == 201
      end
    end

    describe "400 Bad Request" do
      before do
        url = "https://account_sid:token@api.twilio.com/2010-04-01/Accounts/account_sid/SMS/Messages"
        stub_request(:post, url).with(
          :query => {
            "To"    => "+15555555555",
            "From"  => "+13105550000",
            "Body"  => "Hello"
          },
          :headers => {
            "User-Agent" => "em-twilio #{EM::Twilio::VERSION}"
          }
        ).to_return(fixture("bad_request_invalid_phone.txt"))
      end

      it "logs error message" do
        sms = EM::Twilio::SMS.new("+15555555555", "+13105550000", "Hello")
        sms.should_receive(:error).with(
          "code=400 message='+15555555555 is not a valid phone number'"
        )

        lambda {
          EM.run_block { sms.deliver }
        }.should raise_error
      end

      it "raises RequestError" do
        sms = EM::Twilio::SMS.new("+15555555555", "+13105550000", "Hello")

        lambda {
          EM.run_block { sms.deliver }
        }.should raise_error(EM::Twilio::RequestError)
      end
    end

    describe "401 Unauthorized" do
      before do
        EM::Twilio.authenticate("bad_account_sid", "bad_token")

        url = "https://bad_account_sid:bad_token@api.twilio.com/2010-04-01/Accounts/bad_account_sid/SMS/Messages"
        stub_request(:post, url).with(
          :query => {
            "To"    => "+12135550000",
            "From"  => "+13105550000",
            "Body"  => "Hello"
          },
          :headers => {
            "User-Agent" => "em-twilio #{EM::Twilio::VERSION}"
          }
        ).to_return(fixture("unauthorized.txt"))
      end

      it "logs error message" do
        sms = EM::Twilio::SMS.new("+12135550000", "+13105550000", "Hello")
        sms.should_receive(:error).with(
          "code=401 message='Authenticate'"
        )

        lambda {
          EM.run_block { sms.deliver }
        }.should raise_error
      end

      it "raises UnauthorizedError" do
        sms = EM::Twilio::SMS.new("+12135550000", "+13105550000", "Hello")

        lambda {
          EM.run_block { sms.deliver }
        }.should raise_error(EM::Twilio::UnauthorizedError)
      end
    end

    describe "500 Server Error (with message)" do
      before do
        url = "https://account_sid:token@api.twilio.com/2010-04-01/Accounts/account_sid/SMS/Messages"
        stub_request(:post, url).with(
          :query => {
            "To"    => "+12135550000",
            "From"  => "+13105550000",
            "Body"  => "Hello"
          },
          :headers => {
            "User-Agent" => "em-twilio #{EM::Twilio::VERSION}"
          }
        ).to_return(fixture("server_error_with_message.txt"))
      end

      it "logs error message and raises error" do
        sms = EM::Twilio::SMS.new("+12135550000", "+13105550000", "Hello")
        sms.should_receive(:error).with(
          "code=500 message='Internal Failure'"
        )

        lambda {
          EM.run_block { sms.deliver }
        }.should raise_error(EM::Twilio::ServerError)
      end
    end

    describe "500 Server Error (without message)" do
      before do
        url = "https://account_sid:token@api.twilio.com/2010-04-01/Accounts/account_sid/SMS/Messages"
        stub_request(:post, url).with(
          :query => {
            "To"    => "+12135550000",
            "From"  => "+13105550000",
            "Body"  => "Hello"
          },
          :headers => {
            "User-Agent" => "em-twilio #{EM::Twilio::VERSION}"
          }
        ).to_return(fixture("server_error_without_message.txt"))
      end

      it "logs response body and raises error" do
        sms = EM::Twilio::SMS.new("+12135550000", "+13105550000", "Hello")
        sms.should_receive(:error).with(
          "code=500 message='Internal Server Error'"
        )

        lambda {
          EM.run_block { sms.deliver }
        }.should raise_error(EM::Twilio::ServerError)
      end
    end

    describe "502 Bad Gateway" do
      before do
        url = "https://account_sid:token@api.twilio.com/2010-04-01/Accounts/account_sid/SMS/Messages"
        stub_request(:post, url).with(
          :query => {
            "To"    => "+12135550000",
            "From"  => "+13105550000",
            "Body"  => "Hello"
          },
          :headers => {
            "User-Agent" => "em-twilio #{EM::Twilio::VERSION}"
          }
        ).to_return(fixture("bad_gateway.txt"))
      end

      it "logs error message and raises error" do
        sms = EM::Twilio::SMS.new("+12135550000", "+13105550000", "Hello")
        sms.should_receive(:error).with(
          "code=502 message='Bad Gateway'"
        )

        lambda {
          EM.run_block { sms.deliver }
        }.should raise_error(EM::Twilio::ServiceUnavailableError)
      end
    end

    describe "503 ServiceUnavailable" do
      before do
        url = "https://account_sid:token@api.twilio.com/2010-04-01/Accounts/account_sid/SMS/Messages"
        stub_request(:post, url).with(
          :query => {
            "To"    => "+12135550000",
            "From"  => "+13105550000",
            "Body"  => "Hello"
          },
          :headers => {
            "User-Agent" => "em-twilio #{EM::Twilio::VERSION}"
          }
        ).to_return(fixture("service_unavailable.txt"))
      end

      it "logs error message and raises error" do
        sms = EM::Twilio::SMS.new("+12135550000", "+13105550000", "Hello")
        sms.should_receive(:error).with(
          "code=503 message='Service Unavailable'"
        )

        lambda {
          EM.run_block { sms.deliver }
        }.should raise_error(EM::Twilio::ServiceUnavailableError)
      end
    end
  end
end
