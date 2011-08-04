require 'spec_helper'

describe EventMachine::Twilio::SMS do
  describe "#split" do
    it "does not partition fewer than 160 characters" do
      text = "1" * 159
      EM::Twilio::SMS.split(text).should == [text]
    end

    it "paritions at the word boundary if longer than 160 characters" do
      word_1 = "1" * 150
      word_2 = "2" * 11
      EM::Twilio::SMS.split(word_1 + " " + word_2).should == [word_1, word_2]
    end

    it "truncates word when it is longer than 160 characters" do
      word = "1" * 161
      expected = word[0..156] + "..."
      expected.size.should == 160
      EM::Twilio::SMS.split(word).should == [expected]
    end

    it "partitions an example long message" do
      text = ("x" * 160) + " - leftover "
      EM::Twilio::SMS.split(text).should == [
        "x" * 160,
        "- leftover"
      ]
    end

    it "ignores blank partitions" do
      text = ("x" * 160) + " \n\n\n"
      EM::Twilio::SMS.split(text).should == [
        "x" * 160
      ]
    end
  end

  describe "#deliver" do
    before do
      EM::Twilio.authenticate("account_sid", "token")
    end

    describe "201 Created" do
      before do
        url = "https://api.twilio.com/2010-04-01/Accounts/account_sid/SMS/Messages"
        stub_request(:post, url).with(
          :query => {
            "To"    => "+12135550000",
            "From"  => "+13105550000",
            "Body"  => "Hello"
          },
          :headers => {
            "Authorization" => [EM::Twilio.account_sid, EM::Twilio.token],
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

        EM.run_block { @response = sms.deliver }
        @response.first.response_header.status.should == 201
      end
    end

    describe "400 Bad Request" do
      before do
        url = "https://api.twilio.com/2010-04-01/Accounts/account_sid/SMS/Messages"
        stub_request(:post, url).with(
          :query => {
            "To"    => "+15555555555",
            "From"  => "+13105550000",
            "Body"  => "Hello"
          },
          :headers => {
            "Authorization" => [EM::Twilio.account_sid, EM::Twilio.token],
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

        url = "https://api.twilio.com/2010-04-01/Accounts/bad_account_sid/SMS/Messages"
        stub_request(:post, url).with(
          :query => {
            "To"    => "+12135550000",
            "From"  => "+13105550000",
            "Body"  => "Hello"
          },
          :headers => {
            "Authorization" => [EM::Twilio.account_sid, EM::Twilio.token],
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
        url = "https://api.twilio.com/2010-04-01/Accounts/account_sid/SMS/Messages"
        stub_request(:post, url).with(
          :query => {
            "To"    => "+12135550000",
            "From"  => "+13105550000",
            "Body"  => "Hello"
          },
          :headers => {
            "Authorization" => [EM::Twilio.account_sid, EM::Twilio.token],
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
        url = "https://api.twilio.com/2010-04-01/Accounts/account_sid/SMS/Messages"
        stub_request(:post, url).with(
          :query => {
            "To"    => "+12135550000",
            "From"  => "+13105550000",
            "Body"  => "Hello"
          },
          :headers => {
            "Authorization" => [EM::Twilio.account_sid, EM::Twilio.token],
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
        url = "https://api.twilio.com/2010-04-01/Accounts/account_sid/SMS/Messages"
        stub_request(:post, url).with(
          :query => {
            "To"    => "+12135550000",
            "From"  => "+13105550000",
            "Body"  => "Hello"
          },
          :headers => {
            "Authorization" => [EM::Twilio.account_sid, EM::Twilio.token],
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
        url = "https://api.twilio.com/2010-04-01/Accounts/account_sid/SMS/Messages"
        stub_request(:post, url).with(
          :query => {
            "To"    => "+12135550000",
            "From"  => "+13105550000",
            "Body"  => "Hello"
          },
          :headers => {
            "Authorization" => [EM::Twilio.account_sid, EM::Twilio.token],
            "User-Agent"    => "em-twilio #{EM::Twilio::VERSION}"
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

    describe "timeout and other network errors" do
      before do
        url = "https://api.twilio.com/2010-04-01/Accounts/account_sid/SMS/Messages"
        stub_request(:post, url).with(
          :query => {
            "To"    => "+12135550000",
            "From"  => "+13105550000",
            "Body"  => "Hello"
          },
          :headers => {
            "Authorization" => [EM::Twilio.account_sid, EM::Twilio.token],
            "User-Agent" => "em-twilio #{EM::Twilio::VERSION}"
          }
        ).to_timeout
      end

      it "logs error and raises" do
        sms = EM::Twilio::SMS.new("+12135550000", "+13105550000", "Hello")
        sms.should_receive(:error).with("network error: WebMock timeout error")

        lambda {
          EM.run_block { sms.deliver }
        }.should raise_error(EM::Twilio::NetworkError)
      end
    end
  end
end
