require "spec_helper"

describe EventMachine::Twilio do
  describe "#send_sms" do
    it "raises MissingCredentialsError if missing credentials" do
      lambda {
        EM::Twilio.send_sms("+12135550000", "+13105550000", "Hello")
      }.should raise_error(EM::Twilio::MissingCredentialsError)
    end

    it "creates an SMS message and delivers it" do
      EM::Twilio.authenticate("foo", "bar")

      mock_sms = mock(EM::Twilio::SMS)
      mock_sms.should_receive(:deliver).once
      EM::Twilio::SMS.should_receive(:new).with("+12135550000", "+13105550000", "Hello").and_return(mock_sms)

      EM::Twilio.send_sms("+12135550000", "+13105550000", "Hello")
    end

    # This basically tests that the block is passed all the way down
    it "calls block with SID on success" do
      EM::Twilio.authenticate("account_sid", "token")
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

        EM.run_block do
          EM::Twilio.send_sms("+12135550000", "+13105550000", "Hello") do |sid, error|
            sid.should == "SM805624cca3b410ad489c9e6dcf116b87"
            error.should be_nil
          end
        end
    end
  end

  describe "#authenticate" do
    it "sets account_sid and token" do
      EM::Twilio.authenticate("foo", "bar")
      EM::Twilio.account_sid.should == "foo"
      EM::Twilio.token.should == "bar"
    end
  end
end
