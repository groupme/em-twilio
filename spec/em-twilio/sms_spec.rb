require 'spec_helper'

describe EventMachine::Twilio::SMS do
  describe "#deliver" do
    before do
      EM::Twilio.authenticate("account_sid", "token")
    end

    describe "201 Created" do
      before do
        url = "https://api.twilio.com/2010-04-01/Accounts/account_sid/SMS/Messages"
        stub_request(:post, url).with(
          :body => {
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

      it "calls block with response" do
        EM.run_block do
          sms = EM::Twilio::SMS.new("+12135550000", "+13105550000", "Hello")
          sms.deliver { |response|
            response.should be_success
            response.sid.should == "SM805624cca3b410ad489c9e6dcf116b87"
          }
        end
      end
    end

    describe "400 Bad Request" do
      before do
        url = "https://api.twilio.com/2010-04-01/Accounts/account_sid/SMS/Messages"
        stub_request(:post, url).with(
          :body => {
            "To"    => "+15555555555",
            "From"  => "+13105550000",
            "Body"  => "Hello"
          },
          :headers => {
            "authorization" => [EM::Twilio.account_sid, EM::Twilio.token],
            "User-Agent" => "em-twilio #{EM::Twilio::VERSION}"
          }
        ).to_return(fixture("bad_request_invalid_phone.txt"))
      end

      it "calls block with response" do
        EM.run_block do
          sms = EM::Twilio::SMS.new("+15555555555", "+13105550000", "Hello")
          sms.deliver { |response|
            response.should_not be_success
            response.sid.should be_nil
            response.error.should be_a_kind_of(EM::Twilio::RequestError)
          }
        end
      end
    end

    describe "401 Unauthorized" do
      before do
        EM::Twilio.authenticate("bad_account_sid", "bad_token")

        url = "https://api.twilio.com/2010-04-01/Accounts/bad_account_sid/SMS/Messages"
        stub_request(:post, url).with(
          :body => {
            "To"    => "+12135550000",
            "From"  => "+13105550000",
            "Body"  => "Hello"
          },
          :headers => {
            "authorization" => [EM::Twilio.account_sid, EM::Twilio.token],
            "User-Agent" => "em-twilio #{EM::Twilio::VERSION}"
          }
        ).to_return(fixture("unauthorized.txt"))
      end

      it "calls block with error when present" do
        EM.run_block do
          sms = EM::Twilio::SMS.new("+12135550000", "+13105550000", "Hello")
          sms.deliver { |response|
            response.sid.should be_nil
            response.error.should be_a_kind_of(EM::Twilio::UnauthorizedError)
          }
        end
      end
    end

    describe "500 Server Error (with message)" do
      before do
        url = "https://api.twilio.com/2010-04-01/Accounts/account_sid/SMS/Messages"
        stub_request(:post, url).with(
          :body => {
            "To"    => "+12135550000",
            "From"  => "+13105550000",
            "Body"  => "Hello"
          },
          :headers => {
            "authorization" => [EM::Twilio.account_sid, EM::Twilio.token],
            "User-Agent" => "em-twilio #{EM::Twilio::VERSION}"
          }
        ).to_return(fixture("server_error_with_message.txt"))
      end

      it "calls block with error when present" do
        EM.run_block do
          sms = EM::Twilio::SMS.new("+12135550000", "+13105550000", "Hello")
          sms.deliver { |response|
            response.sid.should be_nil
            response.error.should be_a_kind_of(EM::Twilio::ServerError)
          }
        end
      end
    end

    describe "500 Server Error (without message)" do
      before do
        url = "https://api.twilio.com/2010-04-01/Accounts/account_sid/SMS/Messages"
        stub_request(:post, url).with(
          :body => {
            "To"    => "+12135550000",
            "From"  => "+13105550000",
            "Body"  => "Hello"
          },
          :headers => {
            "authorization" => [EM::Twilio.account_sid, EM::Twilio.token],
            "User-Agent" => "em-twilio #{EM::Twilio::VERSION}"
          }
        ).to_return(fixture("server_error_without_message.txt"))
      end

      it "calls block with error when present" do
        EM.run_block do
          sms = EM::Twilio::SMS.new("+12135550000", "+13105550000", "Hello")
          sms.deliver { |response|
            response.sid.should be_nil
            response.error.should be_a_kind_of(EM::Twilio::ServerError)
          }
        end
      end
    end

    describe "502 Bad Gateway" do
      before do
        url = "https://api.twilio.com/2010-04-01/Accounts/account_sid/SMS/Messages"
        stub_request(:post, url).with(
          :body => {
            "To"    => "+12135550000",
            "From"  => "+13105550000",
            "Body"  => "Hello"
          },
          :headers => {
            "authorization" => [EM::Twilio.account_sid, EM::Twilio.token],
            "User-Agent" => "em-twilio #{EM::Twilio::VERSION}"
          }
        ).to_return(fixture("bad_gateway.txt"))
      end

      it "calls block with error when present" do
        EM.run_block do
          sms = EM::Twilio::SMS.new("+12135550000", "+13105550000", "Hello")
          sms.deliver { |response|
            response.sid.should be_nil
            response.error.should be_a_kind_of(EM::Twilio::ServiceUnavailableError)
          }
        end
      end
    end

    describe "503 ServiceUnavailable" do
      before do
        url = "https://api.twilio.com/2010-04-01/Accounts/account_sid/SMS/Messages"
        stub_request(:post, url).with(
          :body => {
            "To"    => "+12135550000",
            "From"  => "+13105550000",
            "Body"  => "Hello"
          },
          :headers => {
            "authorization" => [EM::Twilio.account_sid, EM::Twilio.token],
            "User-Agent"    => "em-twilio #{EM::Twilio::VERSION}"
          }
        ).to_return(fixture("service_unavailable.txt"))
      end

      it "calls block with error when present" do
        EM.run_block do
          sms = EM::Twilio::SMS.new("+12135550000", "+13105550000", "Hello")
          sms.deliver { |response|
            response.should_not be_success
            response.sid.should be_nil
            response.error.should be_a_kind_of(EM::Twilio::ServiceUnavailableError)
          }
        end
      end
    end

    describe "timeout and other network errors" do
      before do
        url = "https://api.twilio.com/2010-04-01/Accounts/account_sid/SMS/Messages"
        stub_request(:post, url).with(
          :body => {
            "To"    => "+12135550000",
            "From"  => "+13105550000",
            "Body"  => "Hello"
          },
          :headers => {
            "authorization" => [EM::Twilio.account_sid, EM::Twilio.token],
            "User-Agent" => "em-twilio #{EM::Twilio::VERSION}"
          }
        ).to_timeout
      end

      it "calls block with error when present" do
        EM.run_block do
          sms = EM::Twilio::SMS.new("+12135550000", "+13105550000", "Hello")
          sms.deliver { |response|
            response.sid.should be_nil
            response.error.should be_a_kind_of(EM::Twilio::NetworkError)
          }
        end
      end
    end
  end
end
