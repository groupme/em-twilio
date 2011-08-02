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
  end

  describe "#authenticate" do
    it "sets account_sid and token" do
      EM::Twilio.authenticate("foo", "bar")
      EM::Twilio.account_sid.should == "foo"
      EM::Twilio.token.should == "bar"
    end
  end
end
