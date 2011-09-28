require 'spec_helper'

describe EventMachine::Twilio::Response do
  describe "#success?" do
    it "is true when status is 201" do
      response = EM::Twilio::Response.new(
        :status => 201
      )
      response.should be_success
    end

    it "is false when status is not 201" do
      response = EM::Twilio::Response.new(
        :status => 400
      )
      response.should_not be_success
    end
  end

  describe "#duration" do
    it "computes now from start time" do
      now = Time.now
      Time.stub!(:now).and_return(now)
      response = EM::Twilio::Response.new({}, now - 5)
      response.duration.should == 5000 # ms
    end

    it "returns nil unless start" do
      response = EM::Twilio::Response.new
      response.duration.should be_nil
    end
  end
end
